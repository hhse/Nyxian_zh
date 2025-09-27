/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <mach/exc.h>
#include <mach/exception.h>
#include <mach/exception_types.h>
#include <mach/thread_state.h>
#include "litehook.h"
#include "Utils.h"

void signal_handler(int code)
{
    __builtin_trap();
}

const char *exceptionName(exception_type_t exception)
{
    switch(exception)
    {
        case EXC_BAD_ACCESS: return "EXC_BAD_ACCESS";
        case EXC_BAD_INSTRUCTION: return "EXC_BAD_ACCESS";
        case EXC_ARITHMETIC: return "EXC_BAD_ACCESS";
        case EXC_EMULATION: return "EXC_EMULATION";
        case EXC_SOFTWARE: return "EXC_SOFTWARE";
        case EXC_BREAKPOINT: return "EXC_BREAKPOINT";
        case EXC_SYSCALL: return "EXC_SYSCALL";
        case EXC_MACH_SYSCALL: return "EXC_MACH_SYSCALL";
        case EXC_RPC_ALERT: return "EXC_RPC_ALERT";
        case EXC_CRASH: return "EXC_CRASH";
        case EXC_RESOURCE: return "EXC_RESOURCE";
        case EXC_GUARD: return "EXC_GUARD";
        case EXC_CORPSE_NOTIFY: return "EXC_CORPSE_NOTIFY";
        default: return "EXC_UNKNOWN";
    }
}

kern_return_t mach_exception_self_server_handler(mach_port_t task,
                                                 mach_port_t thread,
                                                 exception_type_t exception,
                                                 mach_exception_data_type_t *code,
                                                 mach_msg_type_number_t codeCnt)
{
    arm_thread_state64_t state;
    mach_msg_type_number_t count = ARM_THREAD_STATE64_COUNT;
    thread_get_state(thread, ARM_THREAD_STATE64, (thread_state_t)&state, &count);
    
    printf("\nException\n[%s] thread %d faulting at 0x%llx(%s)\n\nRegister\n"
             "PC: 0x%llx\nSP: 0x%llx\nFP: 0x%llx\nLR: 0x%llx\nCPSR: 0x%x\nPAD: 0x%x",
             exceptionName(exception),
             get_thread_index_from_port(thread),
             state.__pc,
             symbol_for_address((void*)state.__pc),
             state.__pc,
             state.__sp,
             state.__fp,
             state.__lr,
             state.__cpsr,
             state.__pad);
    
    for(uint8_t i = 0; i < 29; i++)
        printf("\nX%d: 0x%llx",
                i,
                state.__x[i]);
    
    stack_trace_from_thread_state(state);
    
    state.__pc = (uint64_t)exit;
    state.__x[0] = 1;
    thread_set_state(thread, ARM_THREAD_STATE64, (thread_state_t)&state, count);
    
    printf("\nTask suspended!\n");
    fflush(stdout);
    task_suspend(task);
    
    return KERN_SUCCESS;
}

void* mach_exception_self_server(void *arg)
{
    // Our task is the target, the exception port as the receive side of the kernel exception messages, the mask is basically controlling to what our exception server reacts to
    task_t task = mach_task_self();
    mach_port_t exceptionPort = MACH_PORT_NULL;
    exception_mask_t  mask = EXC_MASK_BAD_ACCESS | EXC_MASK_BAD_INSTRUCTION | EXC_MASK_ARITHMETIC | EXC_MASK_SOFTWARE | EXC_MASK_BREAKPOINT | EXC_MASK_SYSCALL | EXC_MASK_CRASH;
    
    // Allocating mach port and setting it up with our process
    mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE, &exceptionPort);
    mach_port_insert_right(task, exceptionPort, exceptionPort, MACH_MSG_TYPE_MAKE_SEND);
    task_set_exception_ports(task, mask, exceptionPort, EXCEPTION_STATE_IDENTITY, ARM_THREAD_STATE64);
    
    // Thanks to microsoft, without you this wouldnt be possible and I wouldnt understand yet what to do. The request is send by the kernel to our mach port
    __Request__exception_raise_t *request = NULL;
    size_t request_size = round_page(sizeof(*request));
    kern_return_t kr;
    mach_msg_return_t mr;
    
    // Allocating the request structure to have a writing destination
    kr = vm_allocate(mach_task_self(), (vm_address_t *) &request, request_size, VM_FLAGS_ANYWHERE);
    if(kr != KERN_SUCCESS)
    {
        // Shouldn't happen ...
        fprintf(stderr, "Unexpected error in vm_allocate(): %x\n", kr);
        return NULL;
    }
    
    while(1)
    {
        // Now requesting the message and waiting on a reply from the kernel.. happens on exception
        request->Head.msgh_local_port = exceptionPort;
        request->Head.msgh_size = (mach_msg_size_t)request_size;
        mr = mach_msg(&request->Head,
                      MACH_RCV_MSG | MACH_RCV_LARGE,
                      0,
                      request->Head.msgh_size,
                      exceptionPort,
                      MACH_MSG_TIMEOUT_NONE,
                      MACH_PORT_NULL);
        
        // Microsofts code to handle if the exception message send by the kernel is valid to process
        if(mr != MACH_MSG_SUCCESS && mr == MACH_RCV_TOO_LARGE)
        {
            // Determine the new size (before dropping the buffer)
            request_size = round_page(request->Head.msgh_size);
            
            // Drop the old receive buffer
            vm_deallocate(mach_task_self(), (vm_address_t) request, request_size);
            
            // Re-allocate a larger receive buffer
            kr = vm_allocate(mach_task_self(), (vm_address_t *) &request, request_size, VM_FLAGS_ANYWHERE);
            if(kr != KERN_SUCCESS)
            {
                // Shouldn't happen ...
                fprintf(stderr, "Unexpected error in vm_allocate(): 0x%x\n", kr);
                return NULL;
            }
           
            continue;
            
        }
        else if (mr != MACH_MSG_SUCCESS)
            exit(-1);
        
        // Sanity checks
        if (request->Head.msgh_size < sizeof(*request) || request_size - sizeof(*request) < (sizeof(mach_exception_data_type_t) * request->codeCnt))
            exit(-1);
        
        mach_exception_data_type_t *code64 = (mach_exception_data_type_t *) request->code;
        
        // The final exception handler
        kr = mach_exception_self_server_handler(request->task.name,
                                                request->thread.name,
                                                request->exception, code64,
                                                request->codeCnt);
        
        // The faulting thread will be stopped until the reply was send to the kernel
        __Reply__exception_raise_t reply;
        memset(&reply, 0, sizeof(reply));
        reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request->Head.msgh_bits), 0);
        reply.Head.msgh_id = request->Head.msgh_id + 100;
        reply.Head.msgh_local_port = MACH_PORT_NULL;
        reply.Head.msgh_remote_port = request->Head.msgh_remote_port;
        reply.Head.msgh_size = sizeof(reply);
        reply.NDR = NDR_record;
        reply.RetCode = kr;
        mr = mach_msg(&reply.Head, MACH_SEND_MSG, reply.Head.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        if(mr != KERN_SUCCESS)
            exit(-1);
    }
}

void machServerInit(void)
{
    // Dispatching once cuz the mach server shall only be initilized once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Setting each signal to be blocked, in order to make the threads stop on fault, in the past it just continued running
        sigset_t set;
        sigfillset(&set);
        sigdelset(&set, SIGKILL);
        sigdelset(&set, SIGSTOP);
        sigdelset(&set, SIGABRT);
        sigdelset(&set, SIGTERM);
        
        // Using sigprocmask because according to libc source pthread_sigmask is just sigprocmask
        sigprocmask(SIG_BLOCK, &set, NULL);
        
        // Its raised by stuff like malloc API symbols but doesnt matter so much... we raise the mach exception manually in our abort handler. the thread wont continue running as its literally raised by the abort() function that calls based on libc source raise(SIGABRT) which mean it directly jump to our handler.
        signal(SIGABRT, signal_handler);
        
        // Executing finally out mach exception server
        pthread_t serverThread;
        pthread_create(&serverThread,
                       NULL,
                       mach_exception_self_server,
                       NULL);
        
        // Detach thread to automatically release its resources when it returns, cuz we wont join it
        pthread_detach(serverThread);
    });
}
