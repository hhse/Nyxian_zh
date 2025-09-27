//
//  Tweaks.h
//  LiveContainer
//
//  Created by s s on 2025/2/7.
//

bool performHookDyldApi(const char* functionName, uint32_t adrpOffset, void** origFunction, void* hookFunction);

void NUDGuestHooksInit(void);
void SecItemGuestHooksInit(void);
void DyldHooksInit(void);
void NSFMGuestHooksInit(void);

@interface NSBundle(LiveContainer)
- (instancetype)initWithPathForMainBundle:(NSString *)path;
@end


extern uint32_t appMainImageIndex;
extern void* appExecutableHandle;
extern bool tweakLoaderLoaded;
void* getGuestAppHeader(void);
void* dlopenBypassingLock(const char *path, int mode);
void initDead10ccFix(void);
void UIKitGuestHooksInit(void);
void StoreKitHooks_init(void);
