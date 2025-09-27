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
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/ProcEnvironment/cred.h>

DEFINE_HOOK(getuid, uid_t, (void))
{
    // Get proc
    kinfo_info_surface_t object = proc_object_for_pid(getpid());
    return object.real.kp_eproc.e_ucred.cr_uid;
}

DEFINE_HOOK(getgid, uid_t, (void))
{
    // Get proc
    kinfo_info_surface_t object = proc_object_for_pid(getpid());
    return object.real.kp_eproc.e_ucred.cr_groups[0];
}

DEFINE_HOOK(geteuid, uid_t, (void))
{
    // Get proc
    kinfo_info_surface_t object = proc_object_for_pid(getpid());
    return object.real.kp_eproc.e_ucred.cr_uid;
}

DEFINE_HOOK(getegid, uid_t, (void))
{
    // Get proc
    kinfo_info_surface_t object = proc_object_for_pid(getpid());
    return object.real.kp_eproc.e_ucred.cr_groups[0];
}

void environment_cred_init(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(environment_is_role(EnvironmentRoleGuest))
        {
            // Getting credentials
            DO_HOOK_GLOBAL(getuid);
            DO_HOOK_GLOBAL(getgid);
            DO_HOOK_GLOBAL(geteuid);
            DO_HOOK_GLOBAL(getegid);
            
            
            // Setting credentials
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, setuid, environment_proxy_setuid, nil);
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, setgid, environment_proxy_setgid, nil);
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, seteuid, environment_proxy_seteuid, nil);
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, seteuid, environment_proxy_setegid, nil);
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, setruid, environment_proxy_setruid, nil);
            litehook_rebind_symbol(LITEHOOK_REBIND_GLOBAL, setruid, environment_proxy_setrgid, nil);
        }
    });
}
