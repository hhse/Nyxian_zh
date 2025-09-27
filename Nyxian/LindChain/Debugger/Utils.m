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

#include "Utils.h"

const char *symbol_for_address(void *addr)
{
    static char buffer[256];
    Dl_info info;
    if (dladdr(addr, &info) && info.dli_sname)
    {
        snprintf(buffer, sizeof(buffer), "%s", info.dli_sname);
        return buffer;
    }
    return "<unknown>";
}

typedef struct stack_frame {
    struct stack_frame *fp;
    void *lr;
} stack_frame_t;

void stack_trace_from_thread_state(arm_thread_state64_t state)
{
    printf("\n\nFault Trace\n");
    
    stack_frame_t start_frame;
    start_frame.lr = (void*)state.__pc;
    start_frame.fp = (void*)state.__fp;
    stack_frame_t *frame = &start_frame;

    // FIXME: Decompiler gets symbols that shouldnt be there anymore
    int depth = 0;
    while(frame && depth < 1)
    {
        const char *name = symbol_for_address(frame->lr);
        if(strcmp(name, "<unknown>") != 0)
            printf("%s\n%s\n", name, [[Decompiler getDecompiledCodeBuffer:((UInt64)(depth == 0 ? frame->lr : frame->lr - 4))] UTF8String]);
        if(strcmp(name, "main") == 0)
            break;
            
        frame = frame->fp;
        depth++;
    }
}

void stack_trace_from_thread_state_of_task(task_t task,
                                           arm_thread_state64_t state)
{
    // TODO: Implement this, will be needed later
}

uint64_t get_thread_id_from_port(thread_t thread)
{
    thread_identifier_info_data_t info;
    mach_msg_type_number_t count = THREAD_IDENTIFIER_INFO_COUNT;

    kern_return_t kr = thread_info(thread,
                                   THREAD_IDENTIFIER_INFO,
                                   (thread_info_t)&info,
                                   &count);
    if(kr != KERN_SUCCESS)
    {
        fprintf(stderr, "thread_info failed: %d\n", kr);
        return 0;
    }
    return info.thread_id;
}

int get_thread_index_from_port(thread_t target)
{
    thread_act_array_t threads;
    mach_msg_type_number_t count;

    kern_return_t kr = task_threads(mach_task_self(), &threads, &count);
    if (kr != KERN_SUCCESS)
    {
        fprintf(stderr, "task_threads failed: %d\n", kr);
        return -1;
    }

    int index = -1;
    for (mach_msg_type_number_t i = 0; i < count; i++)
    {
        if (threads[i] == target) {
            index = i;
            break;
        }
    }

    for (mach_msg_type_number_t i = 0; i < count; i++)
        mach_port_deallocate(mach_task_self(), threads[i]);

    return index;
}
