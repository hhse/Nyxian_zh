#import <UIKit/UIKit.h>
#import "../LCUtils.h"
#import "UIKitPrivate.h"
#import "utils.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "Localization.h"
#import <LindChain/ObjC/Swizzle.h>
#import <objc/message.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

// Handler for AppDelegate
@implementation UIApplication(LiveContainerHook)

- (void)hook__connectUISceneFromFBSScene:(id)scene transitionContext:(UIApplicationSceneTransitionContext*)context {
#if !TARGET_OS_MACCATALYST
    context.payload = nil;
    context.actions = nil;
#endif
    [self hook__connectUISceneFromFBSScene:scene transitionContext:context];
}

- (void)hook_setDelegate:(id<UIApplicationDelegate>)delegate {
    if(![delegate respondsToSelector:@selector(application:configurationForConnectingSceneSession:options:)]) {
        // Fix old apps black screen when UIApplicationSupportsMultipleScenes is YES
        [ObjCSwizzler replaceInstanceAction:@selector(makeKeyAndVisible) ofClass:UIWindow.class withAction:@selector(hook_makeKeyAndVisible)];
        [ObjCSwizzler replaceInstanceAction:@selector(makeKeyWindow) ofClass:UIWindow.class withAction:@selector(hook_makeKeyWindow)];
        [ObjCSwizzler replaceInstanceAction:@selector(setHidden:) ofClass:UIWindow.class withAction:@selector(hook_setHidden:)];
    }
    [self hook_setDelegate:delegate];
}

+ (BOOL)_wantsApplicationBehaviorAsExtension {
    // Fix LiveProcess: Make _UIApplicationWantsExtensionBehavior return NO so delegate code runs in the run loop
    return YES;
}

@end

@interface UIViewController ()

- (UIInterfaceOrientationMask)__supportedInterfaceOrientations;

@end

@implementation UIViewController (LiveContainerHook)

- (UIInterfaceOrientationMask)hook___supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)hook_shouldAutorotateToInterfaceOrientation:(NSInteger)orientation {
    return YES;
}

@end

@implementation UIWindow (LiveContainerHook)
- (void)hook_setAutorotates:(BOOL)autorotates forceUpdateInterfaceOrientation:(BOOL)force {
    [self hook_setAutorotates:YES forceUpdateInterfaceOrientation:YES];
}

- (void)hook_makeKeyAndVisible {
    [self updateWindowScene];
    [self hook_makeKeyAndVisible];
}
- (void)hook_makeKeyWindow {
    [self updateWindowScene];
    [self hook_makeKeyWindow];
}
- (void)hook_resignKeyWindow {
    [self updateWindowScene];
    [self hook_resignKeyWindow];
}
- (void)hook_setHidden:(BOOL)hidden {
    [self updateWindowScene];
    [self hook_setHidden:hidden];
}
- (void)updateWindowScene {
    UIApplication *app = ((UIApplication *(*)(id, SEL))objc_msgSend)(NSClassFromString(@"UIApplication"), NSSelectorFromString(@"sharedApplication"));
    for(UIWindowScene *windowScene in app.connectedScenes) {
        if(!self.windowScene && self.screen == windowScene.screen) {
            self.windowScene = windowScene;
            break;
        }
    }
}
@end

@interface GridTableCell2 : NSObject
@end

@implementation GridTableCell2

- (void)hook_configureWithId:(int)id columns:(NSArray *)columns size:(CGSize)size
{
    if(columns.count == 0)
        return;
    return [self hook_configureWithId:id columns:columns size:size];
}

@end

void UIKitGuestHooksInit(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ObjCSwizzler replaceInstanceAction:@selector(_connectUISceneFromFBSScene:transitionContext:) ofClass:UIApplication.class withAction:@selector(hook__connectUISceneFromFBSScene:transitionContext:)];
        [ObjCSwizzler replaceInstanceAction:@selector(setDelegate:) ofClass:UIApplication.class withAction:@selector(hook_setDelegate:)];
        [ObjCSwizzler replaceInstanceAction:@selector(__supportedInterfaceOrientations) ofClass:UIViewController.class withAction:@selector(hook___supportedInterfaceOrientations)];
        [ObjCSwizzler replaceInstanceAction:@selector(shouldAutorotateToInterfaceOrientation:) ofClass:UIViewController.class withAction:@selector(hook_shouldAutorotateToInterfaceOrientation:)];
        [ObjCSwizzler replaceInstanceAction:@selector(setAutorotates:forceUpdateInterfaceOrientation:) ofClass:UIWindow.class withAction:@selector(hook_setAutorotates:forceUpdateInterfaceOrientation:)];
        
        Class class = NSClassFromString(@"GridTableCell");
        if(class)
        {
            NSLog(@"Fixing CocoaTop!");
            [ObjCSwizzler replaceInstanceAction:@selector(configureWithId:columns:size:) ofClass:class withAction:@selector(hook_configureWithId:columns:size:) ofClass:GridTableCell2.class];
        }
    });
}

#pragma clang diagnostic pop
