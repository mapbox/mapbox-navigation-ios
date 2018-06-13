#import <Foundation/Foundation.h>

@interface MBBannerComponent : NSObject
- (nonnull instancetype)initWithText:(nonnull NSString *)text
                                type:(nonnull NSString *)type
                                abbr:(nonnull NSString *)abbr
                        abbrPriority:(uint32_t)abbrPriority
                        imageBaseurl:(nonnull NSString *)imageBaseurl;

@property (nonatomic, readonly, nonnull, copy) NSString * text;
@property (nonatomic, readonly, nonnull, copy) NSString * type;
@property (nonatomic, readonly, nonnull, copy) NSString * abbr;
@property (nonatomic, readonly) uint32_t abbrPriority;
@property (nonatomic, readonly, nonnull, copy) NSString * imageBaseurl;
@end
