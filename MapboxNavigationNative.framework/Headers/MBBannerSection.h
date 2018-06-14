#import <Foundation/Foundation.h>

@class MBBannerComponent;

@interface MBBannerSection : NSObject
- (nonnull instancetype)initWithText:(nonnull NSString *)text
                                type:(nonnull NSString *)type
                            modifier:(nonnull NSString *)modifier
                             degrees:(uint32_t)degrees
                         drivingSide:(nonnull NSString *)drivingSide
                          components:(nonnull NSArray<MBBannerComponent *> *)components;

@property (nonatomic, readonly, nonnull, copy) NSString * text;
@property (nonatomic, readonly, nonnull, copy) NSString * type;
@property (nonatomic, readonly, nonnull, copy) NSString * modifier;
@property (nonatomic, readonly) uint32_t degrees;
@property (nonatomic, readonly, nonnull, copy) NSString * drivingSide;
@property (nonatomic, readonly, nonnull, copy) NSArray<MBBannerComponent *> * components;
@end
