#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Install method swizzles on StoreKit entry points and NSBundle receipt URL.
// Safe to call multiple times.
void FragInstallStoreKitHooks(void);

// Toggle: when YES, any [SKPaymentQueue addPayment:] gets intercepted and
// delivered to observers as .purchased immediately, bypassing Apple.
void FragSetAutoGrantEnabled(BOOL enabled);
BOOL FragAutoGrantEnabled(void);

// Fire a .purchased transaction for every productIdentifier in the array.
// Walks [SKPaymentQueue defaultQueue].transactionObservers and dispatches
// a synthetic transaction object to each.
void FragGrantProducts(NSArray<NSString *> *productIdentifiers);

// Fire a fake products response for an in-flight SKProductsRequest so Unity
// IAP's native plugin builds a product catalog without talking to Apple.
void FragDeliverProductsResponse(id request, NSArray<NSString *> *identifiers);

NS_ASSUME_NONNULL_END
