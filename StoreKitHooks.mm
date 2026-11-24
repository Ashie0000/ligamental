#import "StoreKitHooks.h"
#import "UnityBridge.h"
#import "ReceiptForge.h"
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static BOOL gAutoGrant = YES;
static dispatch_queue_t FragStoreQueue(void) {
    static dispatch_queue_t q;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ q = dispatch_queue_create("com.frag.mod.store", DISPATCH_QUEUE_SERIAL); });
    return q;
}

void FragSetAutoGrantEnabled(BOOL enabled) { gAutoGrant = enabled; }
BOOL FragAutoGrantEnabled(void) { return gAutoGrant; }

#pragma mark - Synthetic SKPayment / SKPaymentTransaction / SKProduct / SKProductsResponse

@interface FragSyntheticPayment : NSObject
@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, strong, nullable) NSString *applicationUsername;
@property (nonatomic, assign) BOOL simulatesAskToBuyInSandbox;
@property (nonatomic, strong, nullable) NSData *requestData;
@end
@implementation FragSyntheticPayment
@end

@interface FragSyntheticTransaction : NSObject
@property (nonatomic, strong) FragSyntheticPayment *payment;
@property (nonatomic, assign) SKPaymentTransactionState transactionState;
@property (nonatomic, copy, nullable) NSString *transactionIdentifier;
@property (nonatomic, strong, nullable) NSDate *transactionDate;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, strong, nullable) id originalTransaction;
@property (nonatomic, copy) NSArray *downloads;
@end
@implementation FragSyntheticTransaction
- (NSData *)transactionReceipt {
    return [[FragForgedReceiptBase64() ?: @"" dataUsingEncoding:NSUTF8StringEncoding] copy];
}
@end

@interface FragSyntheticProduct : NSObject
@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, copy) NSString *localizedTitle;
@property (nonatomic, copy) NSString *localizedDescription;
@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, strong) NSLocale *priceLocale;
@property (nonatomic, copy, nullable) NSString *contentVersion;
@property (nonatomic, assign) BOOL isDownloadable;
@property (nonatomic, assign) BOOL downloadable;
@property (nonatomic, copy, nullable) NSArray *downloadContentLengths;
@property (nonatomic, copy, nullable) NSString *subscriptionGroupIdentifier;
@property (nonatomic, strong, nullable) id subscriptionPeriod;
@property (nonatomic, strong, nullable) id introductoryPrice;
@property (nonatomic, copy, nullable) NSArray *discounts;
@end
@implementation FragSyntheticProduct
@end

@interface FragSyntheticProductsResponse : NSObject
@property (nonatomic, copy) NSArray *products;
@property (nonatomic, copy) NSArray<NSString *> *invalidProductIdentifiers;
@end
@implementation FragSyntheticProductsResponse
@end

#pragma mark - Builders

static FragSyntheticTransaction *FragBuildPurchasedTx(NSString *pid) {
    FragSyntheticPayment *pay = [FragSyntheticPayment new];
    pay.productIdentifier = pid;
    pay.quantity = 1;

    FragSyntheticTransaction *tx = [FragSyntheticTransaction new];
    tx.payment = pay;
    tx.transactionState = SKPaymentTransactionStatePurchased;
    tx.transactionIdentifier = [NSString stringWithFormat:@"FRAGMOD-%@-%u",
                                pid, arc4random()];
    tx.transactionDate = [NSDate date];
    tx.downloads = @[];
    return tx;
}

static FragSyntheticProduct *FragBuildProduct(NSString *pid) {
    FragSyntheticProduct *p = [FragSyntheticProduct new];
    p.productIdentifier      = pid;
    p.localizedTitle         = pid;
    p.localizedDescription   = @"Unlocked by FragUnlock";
    p.price                  = [NSDecimalNumber zero];
    p.priceLocale            = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    p.isDownloadable         = NO;
    p.downloadable           = NO;
    p.downloadContentLengths = @[];
    p.discounts              = @[];
    return p;
}

#pragma mark - Delivery

static void FragDeliverTransactionToObservers(FragSyntheticTransaction *tx) {
    SKPaymentQueue *q = [SKPaymentQueue defaultQueue];
    NSArray *observers = nil;
    @try { observers = [[q valueForKey:@"transactionObservers"] copy]; }
    @catch (__unused id e) { observers = @[]; }

    SEL sel = @selector(paymentQueue:updatedTransactions:);
    NSArray *txArr = @[ (id)tx ];
    BOOL delivered = NO;
    for (id obs in observers) {
        if ([obs respondsToSelector:sel]) {
            delivered = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                ((void(*)(id,SEL,id,NSArray *))objc_msgSend)(obs, sel, q, txArr);
            });
        }
    }
    if (!delivered) {
        // Unity IAP may not have registered an SKObserver when the menu is
        // used before the game opened the store: UnitySendMessage fallback.
        FragUnityIAPGrantFallback(tx.payment.productIdentifier);
    }
}

void FragGrantProducts(NSArray<NSString *> *productIdentifiers) {
    dispatch_async(FragStoreQueue(), ^{
        for (NSString *pid in productIdentifiers) {
            FragSyntheticTransaction *tx = FragBuildPurchasedTx(pid);
            FragDeliverTransactionToObservers(tx);
            // Belt-and-braces: fire UnitySendMessage too for games that
            // route through the managed callback instead of SKObserver.
            FragUnityIAPGrantFallback(pid);
        }
    });
}

void FragDeliverProductsResponse(id request, NSArray<NSString *> *identifiers) {
    FragSyntheticProductsResponse *resp = [FragSyntheticProductsResponse new];
    NSMutableArray *prods = [NSMutableArray array];
    for (NSString *pid in identifiers) [prods addObject:FragBuildProduct(pid)];
    resp.products = prods;
    resp.invalidProductIdentifiers = @[];

    id delegate = nil;
    @try { delegate = [request valueForKey:@"delegate"]; }
    @catch (__unused id e) {}
    if (delegate && [delegate respondsToSelector:@selector(productsRequest:didReceiveResponse:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ((void(*)(id,SEL,id,id))objc_msgSend)(delegate,
                @selector(productsRequest:didReceiveResponse:),
                request, resp);
            if ([delegate respondsToSelector:@selector(requestDidFinish:)]) {
                ((void(*)(id,SEL,id))objc_msgSend)(delegate, @selector(requestDidFinish:), request);
            }
        });
    }
}

#pragma mark - Swizzling

static void FragSwizzle(Class cls, SEL orig, SEL repl) {
    Method a = class_getInstanceMethod(cls, orig);
    Method b = class_getInstanceMethod(cls, repl);
    if (!a || !b) return;
    if (class_addMethod(cls, orig,
                        method_getImplementation(b), method_getTypeEncoding(b))) {
        class_replaceMethod(cls, repl,
                            method_getImplementation(a), method_getTypeEncoding(a));
    } else {
        method_exchangeImplementations(a, b);
    }
}

@interface SKPaymentQueue (FragHook) @end
@implementation SKPaymentQueue (FragHook)
- (void)frag_addPayment:(SKPayment *)payment {
    if (!gAutoGrant) { [self frag_addPayment:payment]; return; }
    NSString *pid = payment.productIdentifier ?: @"";
    if (pid.length == 0) { [self frag_addPayment:payment]; return; }
    FragSyntheticTransaction *tx = FragBuildPurchasedTx(pid);
    FragDeliverTransactionToObservers(tx);
    FragUnityIAPGrantFallback(pid);
}
- (void)frag_restoreCompletedTransactions {
    // Fan out every known SKU so the vendor's "Restore" button becomes a
    // grant-everything button when auto-grant is on. Otherwise defer.
    if (gAutoGrant) {
        extern NSArray<NSString *> *FragKnownProductIdentifiers(void);
        FragGrantProducts(FragKnownProductIdentifiers());
    } else {
        [self frag_restoreCompletedTransactions];
    }
}
@end

@interface SKProductsRequest (FragHook) @end
@implementation SKProductsRequest (FragHook)
- (void)frag_start {
    NSSet *ids = nil;
    @try { ids = [self valueForKey:@"productIdentifiers"]; }
    @catch (__unused id e) {}
    if (ids.count == 0) { [self frag_start]; return; }
    FragDeliverProductsResponse(self, ids.allObjects);
}
@end

@interface NSBundle (FragHook) @end
@implementation NSBundle (FragHook)
- (NSURL *)frag_appStoreReceiptURL {
    if (gAutoGrant) return FragForgedReceiptURL();
    return [self frag_appStoreReceiptURL];
}
@end

#pragma mark - Public installer

void FragInstallStoreKitHooks(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        FragSwizzle([SKPaymentQueue class],
                    @selector(addPayment:),
                    @selector(frag_addPayment:));
        FragSwizzle([SKPaymentQueue class],
                    @selector(restoreCompletedTransactions),
                    @selector(frag_restoreCompletedTransactions));
        FragSwizzle([SKProductsRequest class],
                    @selector(start),
                    @selector(frag_start));
        FragSwizzle([NSBundle class],
                    @selector(appStoreReceiptURL),
                    @selector(frag_appStoreReceiptURL));
        (void)FragForgedReceiptURL();
    });
}

// Silence unused-selector warnings in release builds.
__attribute__((used)) static void _FragKeepSynthetics(void) {
    (void)[FragSyntheticPayment class];
    (void)[FragSyntheticTransaction class];
    (void)[FragSyntheticProduct class];
    (void)[FragSyntheticProductsResponse class];
}
