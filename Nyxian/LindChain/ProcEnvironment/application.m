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
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <LindChain/ProcEnvironment/application.h>
#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/ObjC/Swizzle.h>

#pragma mark - UIApplication entry detection (Used to trigger window apparance, headless processes basically)

@implementation UIApplication (ProcEnvironment)

- (void)hook_run
{
    // Only allow client processing
    if(environment_is_role(EnvironmentRoleGuest))
    {
        // Tell host app to let our process appear
        if(!environment_proxy_make_window_visible()) exit(0);
    }
    
    [self hook_run];
}

@end

#pragma mark - Audio background mode fix (Fixes playing music in spotify while spotify is not in nyxians foreground)

@implementation AVAudioSession (ProcEnvironment)

- (BOOL)hook_setActive:(BOOL)active error:(NSError*)outError
{
    [hostProcessProxy setAudioBackgroundModeActive:active];
    return [self hook_setActive:active error:outError];
}

- (BOOL)hook_setActive:(BOOL)active withOptions:(AVAudioSessionSetActiveOptions)options error:(NSError **)outError
{
    [hostProcessProxy setAudioBackgroundModeActive:active];
    return [self hook_setActive:active withOptions:options error:outError];
}


@end


#pragma mark - Initilizer

void environment_application_init(void)
{
    if(environment_is_role(EnvironmentRoleGuest))
    {
        // MARK: GUEST Init
        // MARK: Hooking _run of UIApplication class seems more reliable
        [ObjCSwizzler replaceInstanceAction:@selector(_run) ofClass:UIApplication.class withAction:@selector(hook_run)];
        [ObjCSwizzler replaceInstanceAction:@selector(setActive:error:) ofClass:AVAudioSession.class withAction:@selector(hook_setActive:error:)];
        [ObjCSwizzler replaceInstanceAction:@selector(setActive:withOptions:error:) ofClass:AVAudioSession.class withAction:@selector(hook_setActive:withOptions:error:)];
    }
}
