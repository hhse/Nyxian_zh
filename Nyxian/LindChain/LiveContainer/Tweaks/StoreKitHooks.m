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

#import <StoreKit/StoreKit.h>
#import <LindChain/ObjC/Swizzle.h>

@implementation SKStoreReviewController (LiveContainer)

+ (void)hook_requestReview
{
    // This is not appstore
    return;
}

@end

void StoreKitHooks_init(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ObjCSwizzler replaceClassAction:@selector(requestReview) ofClass:SKStoreReviewController.class withAction:@selector(hook_requestReview)];
    });
}
