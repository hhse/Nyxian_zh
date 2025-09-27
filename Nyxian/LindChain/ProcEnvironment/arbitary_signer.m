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
#import <LindChain/LiveContainer/LCAppInfo.h>
#import <CommonCrypto/CommonDigest.h>

extern NSBundle *overridenNSBundleOfNyxian;

void signMachOAtPath(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *bundlePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"app"]];
    NSString *binPath = [bundlePath stringByAppendingPathComponent:@"main"];
    NSString *infoPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
    
    if([fm fileExistsAtPath:bundlePath]) return;
    
    // Gather signing info
    NSData *certificateData = nil;
    NSString *certificatePassword = nil;
    NSString *extras = nil;
    environment_proxy_gather_code_signature_info(&certificateData, &certificatePassword);
    extras = environment_proxy_gather_code_signature_extras();
    if(!(certificateData && certificatePassword && extras)) return;
    
    NSUserDefaults *appGroupUserDefault = [[NSUserDefaults alloc] initWithSuiteName:LCUtils.appGroupID];
    if(!appGroupUserDefault) appGroupUserDefault = [NSUserDefaults standardUserDefaults];
    [appGroupUserDefault setObject:certificateData forKey:@"LCCertificateData"];
    [appGroupUserDefault setObject:certificatePassword forKey:@"LCCertificatePassword"];
    [appGroupUserDefault setObject:[NSDate now] forKey:@"LCCertificateUpdateDate"];
    [[NSUserDefaults standardUserDefaults] setObject:LCUtils.appGroupID forKey:@"LCAppGroupID"];
    
    // Override signer bundle
    overridenNSBundleOfNyxian = [NSBundle bundleWithPath:extras];
    
    // Create bundle structure
    [fm createDirectoryAtPath:bundlePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Copy binary into bundle
    if (![fm copyItemAtPath:path toPath:binPath error:nil]) {
        return;
    }
    
    // Write Info.plist with hash marker
    NSDictionary *plistDict = @{
        @"CFBundleIdentifier" : overridenNSBundleOfNyxian.bundleIdentifier ?: @"com.nyxian.unsigned",
        @"CFBundleExecutable" : @"main",
        @"CFBundleVersion"    : @"1.0.0"
    };
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:nil];
    [plistData writeToFile:infoPath atomically:YES];
    
    // Run signer
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_queue_create("sign-queue", DISPATCH_QUEUE_CONCURRENT), ^{
    LCAppInfo *appInfo = [[LCAppInfo alloc] initWithBundlePath:bundlePath];
        [appInfo patchExecAndSignIfNeedWithCompletionHandler:^(BOOL succeeded, NSString *errorDescription){
            dispatch_semaphore_signal(sema);
        } progressHandler:^(NSProgress *progress) {
        } forceSign:NO];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    // MARK: Skip using caching, directly replace binary
    [fm removeItemAtPath:path error:nil];
    [fm moveItemAtPath:binPath toPath:path error:nil];
}
