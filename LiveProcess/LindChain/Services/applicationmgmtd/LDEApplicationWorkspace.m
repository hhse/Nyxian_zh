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

#import "LDEApplicationWorkspace.h"
#import <LindChain/Private/FoundationPrivate.h>
#import <LindChain/ProcEnvironment/Server/ServerDelegate.h>
#import <LindChain/LiveContainer/zip.h>
#import <LindChain/Multitask/LDEProcessManager.h>

@interface LDEApplicationWorkspace ()

@property (nonatomic,strong,readwrite) LDEProcess *process;
@property (nonatomic,strong,readwrite) dispatch_semaphore_t sema;

@end

@implementation LDEApplicationWorkspace

- (instancetype)init
{
    self = [super init];
    
    _sema = dispatch_semaphore_create(0);
    
    return [self execute] ? self : nil;
}

- (BOOL)execute
{
    FDMapObject *mapObject = [[FDMapObject alloc] init];
    [mapObject copy_fd_map];
    LDEProcessManager *processManager = [LDEProcessManager shared];
    pid_t pid = [processManager spawnProcessWithItems:@{
        @"endpoint": [ServerDelegate getEndpoint],
        @"executablePath": @"/usr/libexec/applicationmgmtd",
        @"mode": @"management",
        @"mapObject": mapObject
    } withConfiguration:[[LDEProcessConfiguration alloc] initWithParentProcessIdentifier:getpid() withUserIdentifier:0 withGroupIdentifier:0 withEntitlements:PEEntitlementDefaultApplicationManagementDaemon]];
    LDEProcess *process = [processManager processForProcessIdentifier:pid];
    if(!process) return NO;
    
    process.displayName = @"applicationmgmtd";
    
    __weak typeof(self) weakSelf = self;
    [process setRequestInterruptionBlock:^(NSUUID *uuid) {
        dispatch_semaphore_signal(weakSelf.sema);
        weakSelf.sema = dispatch_semaphore_create(0);
        weakSelf.proxy = nil;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf execute];
        });
    }];
    
    self.process = process;
    
    return YES;
}

+ (LDEApplicationWorkspace*)shared
{
    static LDEApplicationWorkspace *applicationWorkspaceSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applicationWorkspaceSingleton = [[LDEApplicationWorkspace alloc] init];
    });
    return applicationWorkspaceSingleton;
}

- (BOOL)installApplicationAtBundlePath:(NSString*)bundlePath
{
    if(!_proxy) return NO;
    __block BOOL result = NO;
    NSString *temporaryPackage = [NSString stringWithFormat:@"%@%@.ipa", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
    if(zipDirectoryAtPath(bundlePath, temporaryPackage, YES)) {
        [_proxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:temporaryPackage] withReply:^(BOOL replyResult){
            result = replyResult;
            dispatch_semaphore_signal(self.sema);
        }];
        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
        [[NSFileManager defaultManager] removeItemAtPath:temporaryPackage error:nil];
    } 
    return result;
}

- (BOOL)installApplicationAtPackagePath:(NSString *)packagePath
{
    if(!_proxy) return NO;
    __block BOOL result = NO;
    [_proxy installApplicationAtBundlePath:[NSFileHandle fileHandleForReadingAtPath:packagePath] withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (BOOL)deleteApplicationWithBundleID:(NSString *)bundleID
{
    if(!_proxy) return NO;
    __block BOOL result = NO;
    [_proxy deleteApplicationWithBundleID:bundleID withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (BOOL)applicationInstalledWithBundleID:(NSString *)bundleID
{
    if(!_proxy) return NO;
    __block BOOL result = NO;
    [_proxy applicationInstalledWithBundleID:bundleID withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (LDEApplicationObject*)applicationObjectForBundleID:(NSString*)bundleID
{
    if(!_proxy) return [[LDEApplicationObject alloc] init];
    __block LDEApplicationObject *result = nil;
    [_proxy applicationObjectForBundleID:bundleID withReply:^(LDEApplicationObject *replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (NSArray<LDEApplicationObject*>*)allApplicationObjects {
    if (!_proxy) return @[];
    __block NSArray<LDEApplicationObject*> *result = nil;
    [_proxy allApplicationObjectsWithReply:^(LDEApplicationObjectArray *replyResult) {
        result = replyResult.applicationObjects;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result ? result : @[];
}

- (BOOL)clearContainerForBundleID:(NSString *)bundleID
{
    if(!_proxy) return NO;
    __block BOOL result = NO;
    [_proxy clearContainerForBundleID:bundleID withReply:^(BOOL replyResult){
        result = replyResult;
        dispatch_semaphore_signal(self.sema);
    }];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return result;
}

@end
