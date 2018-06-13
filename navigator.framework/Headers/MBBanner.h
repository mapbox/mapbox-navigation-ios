#import <Foundation/Foundation.h>

@class MBBannerSection;

@interface MBBanner : NSObject
- (nonnull instancetype)initWithPrimary:(nonnull MBBannerSection *)primary
                              secondary:(nonnull MBBannerSection *)secondary
                                    sub:(nullable MBBannerSection *)sub;

@property (nonatomic, readonly, nonnull) MBBannerSection * primary;
@property (nonatomic, readonly, nonnull) MBBannerSection * secondary;
@property (nonatomic, readonly, nullable) MBBannerSection * sub;
@end
