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
#import <LindChain/ProcEnvironment/Surface/proc.h>
#include <LindChain/ProcEnvironment/Surface/spinlock.h>
#import <pthread.h>
#include <stdio.h>
#include <sys/time.h>

kinfo_info_surface_t proc_object_for_pid(pid_t pid)
{
    kinfo_info_surface_t cur = {};
    
    // Dont use if uninitilized
    if(surface == NULL) return cur;
    
    unsigned long seq;
    do
    {
        seq = spinlock_read_begin(spinface);
        for(uint32_t i = 0; i < surface->proc_count; i++)
        {
            kinfo_info_surface_t object = surface->proc_info[i];
            if(object.real.kp_proc.p_pid == pid)
            {
                cur = object;
                break;
            }
        }
    }
    while (spinlock_read_retry(spinface, seq));
    return cur;
}

void proc_object_remove_for_pid(pid_t pid)
{
    // Dont use if uninitilized
    if(surface == NULL) return;
    
    spinlock_lock(spinface);

    for(uint32_t i = 0; i < surface->proc_count; i++)
    {
        if(surface->proc_info[i].real.kp_proc.p_pid == pid)
        {
            if(i < surface->proc_count - 1)
            {
                memmove(&surface->proc_info[i],
                        &surface->proc_info[i + 1],
                        (surface->proc_count - i - 1) * sizeof(kinfo_info_surface_t));
            }
            surface->proc_count--;
            break;
        }
    }

    spinlock_unlock(spinface);
}

void proc_object_insert(kinfo_info_surface_t object)
{
    // Dont use if uninitilized
    if(surface == NULL) return;
    
    spinlock_lock(spinface);
    
    for(uint32_t i = 0; i < surface->proc_count; i++)
    {
        if(surface->proc_info[i].real.kp_proc.p_pid == object.real.kp_proc.p_pid)
        {
            memcpy(&surface->proc_info[i], &object, sizeof(kinfo_info_surface_t));
            spinlock_unlock(spinface);
            return;
        }
    }
    
    memcpy(&surface->proc_info[surface->proc_count++], &object, sizeof(kinfo_info_surface_t));
    
    spinlock_unlock(spinface);
}

kinfo_info_surface_t proc_object_at_index(uint32_t index)
{
    kinfo_info_surface_t cur = {};
    
    // Dont use if uninitilized
    if(surface == NULL) return cur;
    
    unsigned long seq;
    do
    {
        seq = spinlock_read_begin(spinface);
        if(index < surface->proc_count)
            cur = surface->proc_info[index];
    }
    while (spinlock_read_retry(spinface, seq));
    return cur;
}

// MARK: We need to deprecate this
void proc_insert_self(void)
{
    // Dont use if uninitilized
    if(surface == NULL) return;
    
    pid_t pid = getpid();
    struct kinfo_proc kp;
    size_t len = sizeof(kp);
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
    
    if (sysctl(mib, 4, &kp, &len, NULL, 0) == -1) {
        perror("sysctl");
        return;
    }
    
    char pathbuf[PATH_MAX];
    int proc_pidpath(pid_t pid, void *buf, size_t bufsize);
    proc_pidpath(pid, pathbuf, sizeof(pathbuf));
    
    kinfo_info_surface_t info = {};
    info.real = kp;
    info.force_task_role_override = false;
    info.task_role_override = TASK_UNSPECIFIED;
    strncpy(info.path, pathbuf, sizeof(pathbuf));
    
    proc_object_insert(info);
}

// MARK: New and safer approach, NO means execution not granted!
BOOL proc_create_child_proc(pid_t ppid,
                            pid_t pid,
                            uid_t uid,
                            gid_t gid,
                            NSString *executablePath,
                            PEEntitlement entitlement)
{
    struct kinfo_proc childInfoProc = {};
    
    // Set start time to now
    struct timeval tv;
    if(gettimeofday(&tv, NULL) != 0) return NO;
    childInfoProc.kp_proc.p_un.__p_starttime.tv_sec = tv.tv_sec;
    childInfoProc.kp_proc.p_un.__p_starttime.tv_usec = tv.tv_usec;
    
    // TODO: Make the process a zombie to either get killed or get waited on
    // Set process flag and stat
    childInfoProc.kp_proc.p_flag = P_LP64 | P_EXEC;
    childInfoProc.kp_proc.p_stat = SRUN;
    
    // set process stuff
    childInfoProc.kp_proc.p_pid = pid;
    childInfoProc.kp_proc.p_oppid = ppid;
    
    // Set dupfd
    childInfoProc.kp_proc.p_dupfd = 0;
    
    // set user stack
    childInfoProc.kp_proc.user_stack = 0x0;
    childInfoProc.kp_proc.exit_thread = NULL;
    
    // Set otger things
    childInfoProc.kp_proc.p_debugger = 0;
    childInfoProc.kp_proc.sigwait = 0;
    childInfoProc.kp_proc.p_estcpu = 0;
    childInfoProc.kp_proc.p_cpticks = 0;
    childInfoProc.kp_proc.p_pctcpu = 0;
    childInfoProc.kp_proc.p_wchan = NULL;
    childInfoProc.kp_proc.p_wmesg = NULL;
    childInfoProc.kp_proc.p_swtime = 0;
    childInfoProc.kp_proc.p_slptime = 0;
    childInfoProc.kp_proc.p_realtimer.it_value.tv_sec = 0;
    childInfoProc.kp_proc.p_realtimer.it_value.tv_usec = 0;
    childInfoProc.kp_proc.p_realtimer.it_interval.tv_sec = 0;
    childInfoProc.kp_proc.p_realtimer.it_interval.tv_usec = 0;
    childInfoProc.kp_proc.p_rtime.tv_sec = 0;
    childInfoProc.kp_proc.p_rtime.tv_usec = 0;
    childInfoProc.kp_proc.p_uticks = 0;
    childInfoProc.kp_proc.p_sticks = 0;
    childInfoProc.kp_proc.p_iticks = 0;
    childInfoProc.kp_proc.p_traceflag = 0;
    childInfoProc.kp_proc.p_tracep = NULL;
    childInfoProc.kp_proc.p_siglist = 0;
    childInfoProc.kp_proc.p_textvp = NULL;
    childInfoProc.kp_proc.p_holdcnt = 0;
    childInfoProc.kp_proc.p_sigmask = 0;
    childInfoProc.kp_proc.p_sigignore = 0;
    childInfoProc.kp_proc.p_sigcatch = 0;
    childInfoProc.kp_proc.p_priority = PUSER;
    childInfoProc.kp_proc.p_usrpri = PUSER;
    childInfoProc.kp_proc.p_nice = 0;
    strncpy(childInfoProc.kp_proc.p_comm, [[[NSURL fileURLWithPath:executablePath] lastPathComponent] UTF8String], MAXCOMLEN + 1);
    childInfoProc.kp_proc.p_pgrp = NULL;
    childInfoProc.kp_proc.p_addr = NULL;
    childInfoProc.kp_proc.p_xstat = 0;
    childInfoProc.kp_proc.p_acflag = 2;
    childInfoProc.kp_proc.p_ru = NULL;
    
    childInfoProc.kp_eproc.e_paddr = NULL;
    childInfoProc.kp_eproc.e_sess = NULL;
    
    childInfoProc.kp_eproc.e_pcred.pc_ucred = NULL;
    childInfoProc.kp_eproc.e_pcred.p_ruid = uid;
    childInfoProc.kp_eproc.e_pcred.p_svuid = uid;
    childInfoProc.kp_eproc.e_pcred.p_rgid = gid;
    childInfoProc.kp_eproc.e_pcred.p_svgid = gid;
    childInfoProc.kp_eproc.e_pcred.p_refcnt = 0;
    
    childInfoProc.kp_eproc.e_ucred.cr_ref = 5;
    childInfoProc.kp_eproc.e_ucred.cr_uid = uid;
    childInfoProc.kp_eproc.e_ucred.cr_ngroups = 4;
    childInfoProc.kp_eproc.e_ucred.cr_groups[0] = gid;
    childInfoProc.kp_eproc.e_ucred.cr_groups[1] = 250;
    childInfoProc.kp_eproc.e_ucred.cr_groups[2] = 286;
    childInfoProc.kp_eproc.e_ucred.cr_groups[3] = 299;
    
    childInfoProc.kp_eproc.e_ppid = ppid;
    childInfoProc.kp_eproc.e_pgid = ppid;
    
    childInfoProc.kp_eproc.e_jobc = 0;
    childInfoProc.kp_eproc.e_tdev = -1;
    childInfoProc.kp_eproc.e_tpgid = 0;
    childInfoProc.kp_eproc.e_flag = 2;
    
    kinfo_info_surface_t finalObject = {};
    finalObject.force_task_role_override = true;
    finalObject.task_role_override = TASK_UNSPECIFIED;
    finalObject.real = childInfoProc;
    strncpy(finalObject.path, [[[NSURL fileURLWithPath:executablePath] path] UTF8String], PATH_MAX);
    
    finalObject.entitlements = entitlement;
    
    proc_object_insert(finalObject);
    
    return YES;
}
