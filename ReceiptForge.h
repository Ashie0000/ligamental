#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Build / return the on-disk URL of a canned receipt file.
// The bytes are a minimal PKCS7 envelope that non-verifying readers accept as
// "receipt present". Unity IAP's native plugin reads the data blob and
// base64-forwards it to managed; only strict validators decode the ASN.1.
NSURL *FragForgedReceiptURL(void);

// Base64 string of the receipt, as the UnityPurchasing payload expects.
NSString *FragForgedReceiptBase64(void);

NS_ASSUME_NONNULL_END
