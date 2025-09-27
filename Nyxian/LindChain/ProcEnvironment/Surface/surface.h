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

#ifndef PROCENVIRONMENT_SURFACE_H
#define PROCENVIRONMENT_SURFACE_H

#import <Foundation/Foundation.h>
#include <sys/sysctl.h>
#include <limits.h>
#include <LindChain/ProcEnvironment/Surface/spinlock.h>
#import <LindChain/ProcEnvironment/Surface/entitlement.h>

// Minimal stubs if <libproc.h> is not available
#ifndef PROC_PIDTASKINFO
#define PROC_PIDTASKINFO     4
#endif
#ifndef PROC_PIDTASKALLINFO
#define PROC_PIDTASKALLINFO  2
#endif

struct proc_taskinfo {
    uint64_t        pti_virtual_size;
    uint64_t        pti_resident_size;
    uint64_t        pti_total_user;
    uint64_t        pti_total_system;
    uint64_t        pti_threads_user;
    uint64_t        pti_threads_system;
    int32_t         pti_policy;
    int32_t         pti_faults;
    int32_t         pti_pageins;
    int32_t         pti_cow_faults;
    int32_t         pti_messages_sent;
    int32_t         pti_messages_received;
    int32_t         pti_syscalls_mach;
    int32_t         pti_syscalls_unix;
    int32_t         pti_csw;
    int32_t         pti_threadnum;
    int32_t         pti_numrunning;
    int32_t         pti_priority;
};

struct proc_bsdinfo {
    uint32_t        pbi_flags;        /* 64bit; emulated etc */
    uint32_t        pbi_status;
    uint32_t        pbi_xstatus;
    uint32_t        pbi_pid;
    uint32_t        pbi_ppid;
    uid_t            pbi_uid;
    gid_t            pbi_gid;
    uid_t            pbi_ruid;
    gid_t            pbi_rgid;
    uid_t            pbi_svuid;
    gid_t            pbi_svgid;
    uint32_t        rfu_1;            /* reserved */
    char            pbi_comm[MAXCOMLEN];
    char            pbi_name[2*MAXCOMLEN];    /* empty if no name is registered */
    uint32_t        pbi_nfiles;
    uint32_t        pbi_pgid;
    uint32_t        pbi_pjobc;
    uint32_t        e_tdev;            /* controlling tty dev */
    uint32_t        e_tpgid;        /* tty process group id */
    int32_t            pbi_nice;
    uint64_t        pbi_start_tvsec;
    uint64_t        pbi_start_tvusec;
};

struct proc_taskallinfo {
    struct proc_bsdinfo   pbsd;
    struct proc_taskinfo  ptinfo;
};

/// Structure that holds process information
typedef struct {
    /* Real structure */
    struct kinfo_proc real;
    
    /* Now we come to my other things */
    /* Because its important */
    char path[PATH_MAX];
    
    /* Storing override flag for TASK_UNSPECIFIED */
    bool force_task_role_override;
    task_role_t task_role_override;
    
    /* Entitlements*/
    PEEntitlement entitlements;
} kinfo_info_surface_t;

#define PROC_MAX 5000

/// Structure that holds surface information and other structures
struct surface_map {
    /* System */
    uint32_t magic;
    char hostname[MAXHOSTNAMELEN];
    
    /* Proc */
    uint32_t proc_count;
    kinfo_info_surface_t proc_info[PROC_MAX];
};

typedef struct surface_map surface_map_t;


/* Proc Macros */
#define SURFACE_PROC_COUNTER_SIZE sizeof(uint32_t)
#define SURFACE_PROC_OBJECT_MAX PROC_MAX
#define SURFACE_PROC_OBJECT_MAX_SIZE sizeof(kinfo_info_surface_t) * SURFACE_PROC_OBJECT_MAX

/* Surface Macros */
#define SURFACE_MAGIC 0xFABCDEFB
#define SURFACE_MAGIC_SIZE sizeof(uint32_t)
#define SURFACE_MAP_SIZE SURFACE_MAGIC_SIZE + SURFACE_PROC_COUNTER_SIZE + SURFACE_PROC_OBJECT_MAX_SIZE

/* Shared properties */
extern surface_map_t *surface;
extern spinlock_t *spinface;

/* Handoff */

/// Returns a process surface file handle to perform a handoff over XPC
NSFileHandle *proc_surface_handoff(void);

/// Returns a safety surface file handle to perform a handoff over XPC
NSFileHandle *proc_safety_handoff(void);

/* libproc */
int proc_libproc_listallpids(void *buffer, int buffersize);
int proc_libproc_name(pid_t pid, void * buffer, uint32_t buffersize);
int proc_libproc_pidpath(pid_t pid, void * buffer, uint32_t buffersize);
int proc_libproc_pidinfo(pid_t pid, int flavor, uint64_t arg, void * buffer, int buffersize);
int proc_libproc_pid_rusage(pid_t pid, int flavor, struct rusage_info_v2 *ri);

/* sysctl */
int proc_sysctl_listproc(void *buffer, size_t buffersize, size_t *needed_out);

void proc_object_remove_for_pid(pid_t pid);

void kern_sethostname(NSString *hostname);

void proc_surface_init(void);

#endif
