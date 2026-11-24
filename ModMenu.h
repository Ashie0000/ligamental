#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FragModMenu : NSObject
+ (instancetype)shared;
- (void)present;
- (void)dismiss;
@end

NS_ASSUME_NONNULL_END
