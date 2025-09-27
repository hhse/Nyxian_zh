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
#import <LindChain/ProcEnvironment/proxy.h>
#include <signal.h>
#include <errno.h>

#define PROXY_MAX_DISPATCH_TIME 1.0
#define PROXY_TYPE_REPLY(type) ^(void (^reply)(type))

NSObject<ServerProtocol> *hostProcessProxy = nil;

static inline id
_Nullable
sync_call_with_timeout(void (^invoke)(void (^reply)(id)))
{
    __block id result = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    invoke(^(id obj){
        result = obj;
        dispatch_semaphore_signal(sem);
    });

    long waited = dispatch_semaphore_wait(
        sem,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PROXY_MAX_DISPATCH_TIME * NSEC_PER_SEC))
    );
    if (waited != 0) return nil; // timeout
    return result;
}

static inline NSArray*
_Nullable
sync_call_with_timeout2(void (^invoke)(void (^reply)(id,id)))
{
    __block NSArray *result = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    invoke(^(id obj, id obj2){
        result = @[obj, obj2];
        dispatch_semaphore_signal(sem);
    });

    long waited = dispatch_semaphore_wait(
        sem,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PROXY_MAX_DISPATCH_TIME * NSEC_PER_SEC))
    );
    if (waited != 0) return nil;
    return result;
}

static inline int
sync_call_with_timeout_int(void (^invoke)(void (^reply)(int)))
{
    __block int result = -1;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    invoke(^(int val){
        result = val;
        dispatch_semaphore_signal(sem);
    });

    long waited = dispatch_semaphore_wait(
        sem,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PROXY_MAX_DISPATCH_TIME * NSEC_PER_SEC))
    );
    return (waited == 0) ? result : -1;
}

static inline BOOL
sync_call_with_timeout_bool(void (^invoke)(void (^reply)(BOOL)))
{
    __block int result = -1;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    invoke(^(BOOL val){
        result = val;
        dispatch_semaphore_signal(sem);
    });

    long waited = dispatch_semaphore_wait(
        sem,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PROXY_MAX_DISPATCH_TIME * NSEC_PER_SEC))
    );
    return (waited == 0) ? result : -1;
}

static inline pid_t
sync_call_with_timeout_pid(void (^invoke)(void (^reply)(pid_t)))
{
    __block int result = -1;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    invoke(^(pid_t val){
        result = val;
        dispatch_semaphore_signal(sem);
    });

    long waited = dispatch_semaphore_wait(
        sem,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PROXY_MAX_DISPATCH_TIME * NSEC_PER_SEC))
    );
    return (waited == 0) ? result : -1;
}

void environment_proxy_set_ldeapplicationworkspace_endpoint(NSXPCListenerEndpoint *endpoint)
{
    environment_must_be_role(EnvironmentRoleGuest);
    [hostProcessProxy setLDEApplicationWorkspaceEndPoint:endpoint];
}

void environment_proxy_tfp_send_port_object(TaskPortObject *port)
{
    environment_must_be_role(EnvironmentRoleGuest);
    [hostProcessProxy sendPort:port];
}

TaskPortObject *environment_proxy_tfp_get_port_object_for_process_identifier(pid_t process_identifier)
{
    environment_must_be_role(EnvironmentRoleGuest);
    TaskPortObject *object = sync_call_with_timeout(PROXY_TYPE_REPLY(TaskPortObject*){
        [hostProcessProxy getPort:process_identifier withReply:reply];
    });
    return object;
}

NSSet *environment_proxy_proc_list_all_process_identifier(void)
{
    environment_must_be_role(EnvironmentRoleGuest);
    NSSet *set = sync_call_with_timeout(PROXY_TYPE_REPLY(NSSet*){
        [hostProcessProxy proc_listallpidsViaReply:reply];
    });
    return set;
}

LDEProcess *environment_proxy_proc_structure_for_process_identifier(pid_t process_identifier)
{
    environment_must_be_role(EnvironmentRoleGuest);
    LDEProcess *process = sync_call_with_timeout(PROXY_TYPE_REPLY(LDEProcess*){
        [hostProcessProxy proc_getProcStructureForProcessIdentifier:process_identifier withReply:reply];
    });
    return process;
}

int environment_proxy_proc_kill_process_identifier(pid_t process_identifier,
                                                   int signal)
{
    environment_must_be_role(EnvironmentRoleGuest);

    if(signal <= 0 || signal >= NSIG)
    {
        errno = EINVAL;
        return -1;
    }

    int result = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy proc_kill:process_identifier
                          withSignal:signal
                           withReply:reply];
    });

    if(result != 0)
    {
        errno = result;
        return -1;
    }

    return 0;
}

BOOL environment_proxy_make_window_visible(void)
{
    environment_must_be_role(EnvironmentRoleGuest);
    BOOL appeared = sync_call_with_timeout_bool(PROXY_TYPE_REPLY(BOOL){
        [hostProcessProxy makeWindowVisibleWithReply:reply];
    });
    return appeared;
}

pid_t environment_proxy_spawn_process_at_path(NSString *path,
                                              NSArray *arguments,
                                              NSDictionary *environment,
                                              FDMapObject *mapObject)
{
    environment_must_be_role(EnvironmentRoleGuest);
    pid_t process_identifier = sync_call_with_timeout_pid(PROXY_TYPE_REPLY(pid_t){
        [hostProcessProxy spawnProcessWithPath:path withArguments:arguments withEnvironmentVariables:environment withMapObject:mapObject withReply:reply];
    });
    return process_identifier;
}

void environment_proxy_gather_code_signature_info(NSData **certificateData, NSString **certificatePassword)
{
    environment_must_be_role(EnvironmentRoleGuest);
    NSArray *array = sync_call_with_timeout2(^(void (^reply)(NSData*,NSString*)){
        [hostProcessProxy gatherCodeSignerViaReply:reply];
    });
    if(!array) return;
    *certificateData = array[0];
    *certificatePassword = array[1];
}

NSString *environment_proxy_gather_code_signature_extras(void)
{
    environment_must_be_role(EnvironmentRoleGuest);
    NSString *extra = sync_call_with_timeout(PROXY_TYPE_REPLY(NSString*){
        [hostProcessProxy gatherSignerExtrasViaReply:reply];
    });
    return extra;
}

void environment_proxy_get_surface_handle(NSFileHandle **surface, NSFileHandle **safety)
{
    environment_must_be_role(EnvironmentRoleGuest);
    NSArray *objectArray = sync_call_with_timeout2(^(void (^reply)(NSFileHandle*, NSFileHandle*)){
        [hostProcessProxy handinSurfaceFileDescriptorViaReply:reply];
    });
    if(!objectArray) return;
    *surface = objectArray[0];
    *safety = objectArray[1];
}

int environment_proxy_setuid(uid_t uid)
{
    environment_must_be_role(EnvironmentRoleGuest);
    int ret = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy setCredentialWithOption:CredentialSetUID withIdentifier:uid withReply:reply];
    });
    return ret;
}

int environment_proxy_setgid(gid_t gid)
{
    environment_must_be_role(EnvironmentRoleGuest);
    int ret = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy setCredentialWithOption:CredentialSetGID withIdentifier:gid withReply:reply];
    });
    return ret;
}

int environment_proxy_seteuid(uid_t uid)
{
    environment_must_be_role(EnvironmentRoleGuest);
    int ret = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy setCredentialWithOption:CredentialSetEUID withIdentifier:uid withReply:reply];
    });
    return ret;
}

int environment_proxy_setegid(gid_t gid)
{
    environment_must_be_role(EnvironmentRoleGuest);
    int ret = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy setCredentialWithOption:CredentialSetEGID withIdentifier:gid withReply:reply];
    });
    return ret;
}

int environment_proxy_setruid(uid_t uid)
{
    environment_must_be_role(EnvironmentRoleGuest);
    int ret = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy setCredentialWithOption:CredentialSetRUID withIdentifier:uid withReply:reply];
    });
    return ret;
}

int environment_proxy_setrgid(gid_t gid)
{
    environment_must_be_role(EnvironmentRoleGuest);
    int ret = sync_call_with_timeout_int(PROXY_TYPE_REPLY(int){
        [hostProcessProxy setCredentialWithOption:CredentialSetRGID withIdentifier:gid withReply:reply];
    });
    return ret;
}
