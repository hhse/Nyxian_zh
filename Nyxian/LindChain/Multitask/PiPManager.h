//
//  PiPManager.h
//  LiveContainer
//
//  Created by s s on 2025/6/3.
//

#ifndef PIPMANAGER_H
#define PIPMANAGER_H

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import "FoundationPrivate.h"
#import "LDEAppScene.h"

@interface PiPManager : NSObject<AVPictureInPictureControllerDelegate>

@property (class, nonatomic, readonly) PiPManager *shared;
@property (nonatomic, readonly) bool isPiP;

- (BOOL)isPiPWithVC:(LDEAppScene*)vc;
- (BOOL)isPiPWithDecoratedVC:(UIViewController*)vc;
- (void)stopPiP;
- (void)startPiPWithVC:(LDEAppScene*)vc;

@end

#endif /* PIPMANAGER_H */
