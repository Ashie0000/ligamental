#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Baked from com.ohbibi.fps v5.7.2 global-metadata.dat
// Three currency tiers per SKU: base, .ct2, .ct3
static NSArray<NSString *> *FragKnownProductIdentifiers(void) {
    static NSArray *ids = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ids = @[
            @"com.ohbibi.fps.diamonds1",            @"com.ohbibi.fps.diamonds1.ct2",            @"com.ohbibi.fps.diamonds1.ct3",
            @"com.ohbibi.fps.diamonds2",            @"com.ohbibi.fps.diamonds2.ct2",            @"com.ohbibi.fps.diamonds2.ct3",
            @"com.ohbibi.fps.diamonds3",            @"com.ohbibi.fps.diamonds3.ct2",            @"com.ohbibi.fps.diamonds3.ct3",
            @"com.ohbibi.fps.diamonds4",            @"com.ohbibi.fps.diamonds4.ct2",            @"com.ohbibi.fps.diamonds4.ct3",
            @"com.ohbibi.fps.diamonds5",            @"com.ohbibi.fps.diamonds5.ct2",            @"com.ohbibi.fps.diamonds5.ct3",
            @"com.ohbibi.fps.diamonds6",            @"com.ohbibi.fps.diamonds6.ct2",            @"com.ohbibi.fps.diamonds6.ct3",
            @"com.ohbibi.fps.diamonds7",            @"com.ohbibi.fps.diamonds7.ct2",            @"com.ohbibi.fps.diamonds7.ct3",
            @"com.ohbibi.fps.diamonds8",            @"com.ohbibi.fps.diamonds8.ct2",            @"com.ohbibi.fps.diamonds8.ct3",
            @"com.ohbibi.fps.weekly.vip",           @"com.ohbibi.fps.weekly.vip.ct2",           @"com.ohbibi.fps.weekly.vip.ct3",
            @"com.ohbibi.fps.monthly.vip",          @"com.ohbibi.fps.monthly.vip.ct2",          @"com.ohbibi.fps.monthly.vip.ct3",
            @"com.ohbibi.fps.standardpass",         @"com.ohbibi.fps.standardandpropass",       @"com.ohbibi.fps.supporteventspin1",
            @"com.ohbibi.fps.speoffer1",            @"com.ohbibi.fps.speoffer1.ct2",            @"com.ohbibi.fps.speoffer1.ct3",
            @"com.ohbibi.fps.speoffer2",            @"com.ohbibi.fps.speoffer2.ct2",            @"com.ohbibi.fps.speoffer2.ct3",
            @"com.ohbibi.fps.speoffer3",            @"com.ohbibi.fps.speoffer3.ct2",            @"com.ohbibi.fps.speoffer3.ct3",
            @"com.ohbibi.fps.speoffer4",            @"com.ohbibi.fps.speoffer4.ct2",            @"com.ohbibi.fps.speoffer4.ct3",
            @"com.ohbibi.fps.speoffer5",            @"com.ohbibi.fps.speoffer5.ct2",            @"com.ohbibi.fps.speoffer5.ct3",
            @"com.ohbibi.fps.speoffer6",            @"com.ohbibi.fps.speoffer6.ct2",            @"com.ohbibi.fps.speoffer6.ct3",
            @"com.ohbibi.fps.speoffer7",            @"com.ohbibi.fps.speoffer7.ct2",            @"com.ohbibi.fps.speoffer7.ct3",
            @"com.ohbibi.fps.speoffer8",            @"com.ohbibi.fps.speoffer8.ct2",            @"com.ohbibi.fps.speoffer8.ct3",
            @"com.ohbibi.fps.speoffer9",            @"com.ohbibi.fps.speoffer9.ct2",            @"com.ohbibi.fps.speoffer9.ct3",
            @"com.ohbibi.fps.speoffer10",           @"com.ohbibi.fps.speoffer10.ct2",           @"com.ohbibi.fps.speoffer10.ct3",
            @"com.ohbibi.fps.speoffer11",           @"com.ohbibi.fps.speoffer11.ct2",           @"com.ohbibi.fps.speoffer11.ct3",
            @"com.ohbibi.fps.speoffer12",           @"com.ohbibi.fps.speoffer12.ct2",           @"com.ohbibi.fps.speoffer12.ct3",
            @"com.ohbibi.fps.speoffer13",           @"com.ohbibi.fps.speoffer13.ct2",           @"com.ohbibi.fps.speoffer13.ct3",
            @"com.ohbibi.fps.speoffer15",           @"com.ohbibi.fps.speoffer15.ct2",           @"com.ohbibi.fps.speoffer15.ct3",
            @"com.ohbibi.fps.speoffer16",           @"com.ohbibi.fps.speoffer16.ct2",           @"com.ohbibi.fps.speoffer16.ct3",
            @"com.ohbibi.fps.speoffer17",           @"com.ohbibi.fps.speoffer17.ct2",           @"com.ohbibi.fps.speoffer17.ct3",
            @"com.ohbibi.fps.speoffer18",           @"com.ohbibi.fps.speoffer18.ct2",           @"com.ohbibi.fps.speoffer18.ct3",
        ];
    });
    return ids;
}

NS_ASSUME_NONNULL_END
