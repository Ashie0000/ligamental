#import "ReceiptForge.h"
#import <Foundation/Foundation.h>

// Minimal PKCS7 signedData envelope containing an empty data payload.
// RFC 2315 — ContentInfo { OID=1.2.840.113549.1.7.2, [0] SignedData { v=1, DigestAlg={}, EncapContentInfo={OID=1.2.840.113549.1.7.1}, Certs=[0], SignerInfos={} } }
// Non-verifying readers see a valid ASN.1 sequence they can forward.
static NSData *FragMinimalPKCS7(void) {
    static const uint8_t bytes[] = {
        0x30, 0x1F,                                                       // SEQUENCE len=31
          0x06, 0x09, 0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x02,       // OID 1.2.840.113549.1.7.2
          0xA0, 0x12,                                                      // [0] len=18
            0x30, 0x10,                                                    // SignedData SEQ len=16
              0x02, 0x01, 0x01,                                            // version=1
              0x31, 0x00,                                                  // digestAlgorithms SET empty
              0x30, 0x0B,                                                  // EncapContentInfo SEQ
                0x06, 0x09, 0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x01,  // OID data
              0x31, 0x00                                                   // signerInfos SET empty
    };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

static NSURL *gCachedReceiptURL = nil;

NSURL *FragForgedReceiptURL(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *dir = NSTemporaryDirectory();
        NSString *path = [dir stringByAppendingPathComponent:@"FragForgedReceipt.bin"];
        NSData *blob = FragMinimalPKCS7();
        [blob writeToFile:path atomically:YES];
        gCachedReceiptURL = [NSURL fileURLWithPath:path];
    });
    return gCachedReceiptURL;
}

NSString *FragForgedReceiptBase64(void) {
    return [FragMinimalPKCS7() base64EncodedStringWithOptions:0];
}
