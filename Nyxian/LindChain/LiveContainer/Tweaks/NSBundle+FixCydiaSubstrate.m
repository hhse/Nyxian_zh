#import <Foundation/Foundation.h>
#import "Tweaks.h"
#import <objc/runtime.h>

@implementation NSString(LiveContainer)

- (NSString *)lc_realpath {
    char result[PATH_MAX];
    realpath(self.fileSystemRepresentation, result);
    return [NSString stringWithUTF8String:result];
}

@end

@implementation NSBundle(LiveContainer)

- (instancetype)initWithPathForMainBundle:(NSString *)path {
    id cfBundle = CFBridgingRelease(CFBundleCreate(NULL, (__bridge CFURLRef)[NSURL fileURLWithPath:path.lc_realpath]));
    if(!cfBundle) return nil;
    self = [self initWithPath:path];
    object_setIvar(self, class_getInstanceVariable(self.class, "_cfBundle"), cfBundle);
    return self;
}

@end
