#import "UnityBridge.h"
#import "ReceiptForge.h"
#import <dlfcn.h>

typedef void (*unity_send_t)(const char *, const char *, const char *);
static unity_send_t gUnitySendMessage = NULL;

static unity_send_t FragResolveUnitySendMessage(void) {
    if (gUnitySendMessage) return gUnitySendMessage;
    void *sym = dlsym(RTLD_DEFAULT, "UnitySendMessage");
    if (!sym) {
        // Unity sometimes ships the C++ mangled or lowercase variant; try both.
        sym = dlsym(RTLD_DEFAULT, "_UnitySendMessage");
    }
    if (!sym) {
        void *fw = dlopen("@executable_path/Frameworks/UnityFramework.framework/UnityFramework", RTLD_LAZY);
        if (fw) sym = dlsym(fw, "UnitySendMessage");
    }
    gUnitySendMessage = (unity_send_t)sym;
    return gUnitySendMessage;
}

BOOL FragUnitySendMessage(const char *gameObject, const char *method, const char *arg) {
    unity_send_t fn = FragResolveUnitySendMessage();
    if (!fn) return NO;
    fn(gameObject, method, arg ?: "");
    return YES;
}

void FragUnityIAPGrantFallback(NSString *productIdentifier) {
    NSString *txId = [NSString stringWithFormat:@"FRAGMOD-%@-%lld",
                      productIdentifier, (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
    NSDictionary *payload = @{
        @"productId":           productIdentifier,
        @"transactionID":       txId,
        @"receipt":             FragForgedReceiptBase64() ?: @"",
        @"storeSpecificErrorCode": @"",
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // Try the common Unity IAP listener names in order; first live GameObject wins.
    const char *candidates[] = {
        "UnityPurchasing",
        "IAPListener",
        "CodelessIAPStoreListener",
        "IAPManager",
        "PurchaseManager",
        NULL
    };
    for (int i = 0; candidates[i]; i++) {
        FragUnitySendMessage(candidates[i], "OnPurchaseSucceeded", json.UTF8String);
    }
}
