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

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ProcEnvironment/Surface/surface.h>
#import <LindChain/ProcEnvironment/Surface/proc.h>
#import <LindChain/ProcEnvironment/Surface/memfd.h>
#import <LindChain/ProcEnvironment/proxy.h>
#import <LindChain/litehook/src/litehook.h>
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>

surface_map_t *surface = NULL;
spinlock_t *spinface = NULL;

static int sharing_fd = -1;
static int safety_fd = -1;

/* sysctl */
int proc_sysctl_listproc(void *buffer, size_t buffersize, size_t *needed_out)
{
    // Dont use if uninitilized
    if(surface == NULL) return 0;
    
    size_t needed_bytes = 0;
    int ret = 0;
    unsigned long seq;

    do {
        seq = spinlock_read_begin(spinface);

        uint32_t count = surface->proc_count;
        needed_bytes = (size_t)count * sizeof(struct kinfo_proc);

        if(needed_out)
            *needed_out = needed_bytes;

        if(buffer == NULL || buffersize == 0)
        {
            ret = (int)needed_bytes;
            break;
        }

        if(buffersize < needed_bytes)
        {
            errno = ENOMEM;
            ret = -1;
            break;
        }

        struct kinfo_proc *kprocs = buffer;
        for(uint32_t i = 0; i < count; i++)
        {
            memset(&kprocs[i], 0, sizeof(struct kinfo_proc));
            memcpy(&kprocs[i],
                   &surface->proc_info[i].real,
                   sizeof(struct kinfo_proc));
        }

        ret = (int)needed_bytes;

    } while (spinlock_read_retry(spinface, seq));

    return ret;
}

bool proc_allowed_to_spawn(void)
{
    return true;
}

/*
 Management
 */
NSFileHandle* proc_surface_handoff(void)
{
    environment_must_be_role(EnvironmentRoleHost);
    return [[NSFileHandle alloc] initWithFileDescriptor:sharing_fd];
}

NSFileHandle *proc_safety_handoff(void)
{
    environment_must_be_role(EnvironmentRoleHost);
    return [[NSFileHandle alloc] initWithFileDescriptor:safety_fd];
}

/*
 Experimental hooks & implementations
 */
int environment_gethostname(char *buf,
                            size_t bufsize)
{
    unsigned long seq;

    do
    {
        seq = spinlock_read_begin(spinface);
        strlcpy(buf, surface->hostname, bufsize);
    }
    while(spinlock_read_retry(spinface, seq));
    
    return 0;
}

void kern_sethostname(NSString *hostname)
{
    spinlock_lock(spinface);
    hostname = hostname ?: @"localhost";
    strlcpy(surface->hostname, [hostname UTF8String], MAXHOSTNAMELEN);
    spinlock_unlock(spinface);
}

void proc_surface_unmap(void)
{
    if(munmap(surface, SURFACE_MAP_SIZE) != 0)
        exit(1);
    else
        surface = NULL;
    if(munmap(spinface, sizeof(spinlock_t)) != 0)
        exit(1);
    else
        spinface = NULL;
}

void proc_surface_init(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Initilize base of mapping
        if(environment_is_role(EnvironmentRoleHost))
        {
            sharing_fd = memfd_create("proc_surface_memfd", O_CREAT | O_RDWR);
            safety_fd = memfd_create("proc_surface_safefd", O_CREAT | O_RDWR);
            if(sharing_fd == -1 || safety_fd == -1) return;
            ftruncate(sharing_fd, SURFACE_MAP_SIZE);
            ftruncate(safety_fd, sizeof(spinlock_t));
        }
        else
        {
            // Setup
            NSFileHandle *handle;
            NSFileHandle *safety;
            environment_proxy_get_surface_handle(&handle, &safety);
            if(!(handle && safety))
            {
                if(handle) [handle closeFile];
                if(safety) [safety closeFile];
                return;
            }
            sharing_fd = handle.fileDescriptor;
            safety_fd = safety.fileDescriptor;
        }
        
        // Now map it!! (but only with max readable)
        // MARK: Will likely deprecate after making shared mapping objects which will transfer a maximum read only memport instead
        int prot = PROT_READ;
        if(environment_is_role(EnvironmentRoleHost)) prot = prot | PROT_WRITE;
        surface = mmap(NULL, SURFACE_MAP_SIZE, prot, MAP_SHARED, sharing_fd, 0);
        spinface = mmap(NULL, sizeof(spinlock_t), prot, MAP_SHARED, safety_fd, 0);
        
        if(environment_is_role(EnvironmentRoleGuest))
        {
            kern_return_t kr = _kernelrpc_mach_vm_protect_trap(mach_task_self(), (mach_vm_address_t)surface, SURFACE_MAP_SIZE, TRUE, VM_PROT_READ);
            if(kr == KERN_SUCCESS) kr = _kernelrpc_mach_vm_protect_trap(mach_task_self(), (mach_vm_address_t)spinface, sizeof(spinlock_t), TRUE, VM_PROT_READ);
            if(kr != KERN_SUCCESS)
            {
                // Sandbox violation!
                proc_surface_unmap();
                return;
            }
        }
        
        if(environment_is_role(EnvironmentRoleGuest) ||
           surface == MAP_FAILED ||
           spinface == MAP_FAILED)
        {
            // Mapping failed
            close(safety_fd);
            close(sharing_fd);
            if(environment_is_role(EnvironmentRoleHost))
                return;
        }
        
        // After close we come to magic
        if(environment_is_role(EnvironmentRoleHost))
        {
            // Were the host so we write the magic
            surface->magic = SURFACE_MAGIC;
            
            // Setup spinface
            spinface->lock = 0;
            spinface->seq = 0;
        }
        else
        {
            // Were the guest so we check the magic
            if(surface->magic != SURFACE_MAGIC)
            {
                proc_surface_unmap();
                return;
            }
        }
        
        // Add proc self if were host
        if(environment_is_role(EnvironmentRoleHost))
        {
            proc_create_child_proc(getppid(), getpid(), 0, 0, [[NSBundle mainBundle] executablePath], PEEntitlementAll);
            
            // Setup hostname
            NSString *hostname = [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEHostname"];
            hostname = hostname ?: @"localhost";
            strlcpy(surface->hostname, [hostname UTF8String], MAXHOSTNAMELEN);
        }
        else
        {
            // Rebind hostname symbol
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, gethostname, environment_gethostname, nil);
        }
    });
}
