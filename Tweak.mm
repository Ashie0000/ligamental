#import <UIKit/UIKit.h>
#import "ModMenu.h"
#import "StoreKitHooks.h"

static void FragBootUp(void) {
    FragInstallStoreKitHooks();
    // Default auto-grant ON unless user has saved a preference previously.
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (![d objectForKey:@"FragUnlock.AutoGrant"]) {
        [d setBool:YES forKey:@"FragUnlock.AutoGrant"];
    }
    FragSetAutoGrantEnabled([d boolForKey:@"FragUnlock.AutoGrant"]);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[FragModMenu shared] present];
    });
}

__attribute__((constructor))
static void FragLoad(void) {
    // Sideloadly rewrites the bundle id to the signer's team namespace; gating
    // on com.ohbibi would miss resigned builds. The dylib only ever lands in
    // this one app anyway, so just arm on load.
    if ([NSThread isMainThread]) FragBootUp();
    else dispatch_async(dispatch_get_main_queue(), ^{ FragBootUp(); });
}
