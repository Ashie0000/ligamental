#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// UnitySendMessage(gameObject, method, arg) resolved at runtime via dlsym.
// Returns NO if the symbol was not found.
BOOL FragUnitySendMessage(const char *gameObject, const char *method, const char *arg);

// Convenience: fire UnityPurchasing-style OnPurchaseSucceeded with a JSON
// payload matching Unity IAP's AppleAppReceipt shape.
void FragUnityIAPGrantFallback(NSString *productIdentifier);

NS_ASSUME_NONNULL_END
