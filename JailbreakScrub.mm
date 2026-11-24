#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/stat.h>
#import <sys/syscall.h>
#import <unistd.h>

// FRAG uses off-the-shelf SDKs (AppLovin, Facebook, Firebase, Vungle, Mintegral).
// Several of these ping standard jailbreak probe paths at init time. Leaving
// those checks tripping can gate telemetry only, but some IAP wrappers also
// refuse to initialize StoreKit under a "compromised" environment, so the
// safer default is to scrub the common probes.

static BOOL FragIsJailbreakProbe(NSString *path) {
    if (path.length == 0) return NO;
    static NSArray<NSString *> *needles = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        needles = @[
            @"/Applications/Cydia.app",
            @"/Applications/Sileo.app",
            @"/Applications/Zebra.app",
            @"/Library/MobileSubstrate",
            @"/usr/libexec/ssh-keysign",
            @"/usr/sbin/sshd",
            @"/usr/bin/ssh",
            @"/bin/bash",
            @"/bin/sh",
            @"/etc/apt",
            @"/private/var/lib/apt",
            @"/private/var/lib/cydia",
            @"/private/var/mobile/Library/SBSettings",
            @"/var/jb",
            @"/var/binpack",
            @"/usr/lib/libjailbreak.dylib",
            @"/usr/lib/libhooker.dylib",
            @"/usr/lib/substrate",
            @"/Library/PreferenceBundles/MobileSubstrate.bundle",
        ];
    });
    for (NSString *n in needles) {
        if ([path hasPrefix:n] || [path containsString:n]) return YES;
    }
    return NO;
}

static void FragSwizzleInstance(Class cls, SEL orig, SEL repl) {
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

@interface NSFileManager (FragScrub) @end
@implementation NSFileManager (FragScrub)
- (BOOL)frag_fileExistsAtPath:(NSString *)path {
    if (FragIsJailbreakProbe(path)) return NO;
    return [self frag_fileExistsAtPath:path];
}
- (BOOL)frag_fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDir {
    if (FragIsJailbreakProbe(path)) { if (isDir) *isDir = NO; return NO; }
    return [self frag_fileExistsAtPath:path isDirectory:isDir];
}
@end

@interface UIApplication_Shim : NSObject @end

@interface NSString (FragScrub) @end
@implementation NSString (FragScrub)
- (BOOL)frag_isJailbreakSchemeURL {
    return [self hasPrefix:@"cydia:"] || [self hasPrefix:@"sileo:"] || [self hasPrefix:@"zbra:"];
}
@end

__attribute__((constructor))
static void FragInstallJailbreakScrubber(void) {
    FragSwizzleInstance([NSFileManager class],
                        @selector(fileExistsAtPath:),
                        @selector(frag_fileExistsAtPath:));
    FragSwizzleInstance([NSFileManager class],
                        @selector(fileExistsAtPath:isDirectory:),
                        @selector(frag_fileExistsAtPath:isDirectory:));
}
