#import <Foundation/Foundation.h>

@interface MBVoiceInstruction : NSObject
- (nonnull instancetype)initWithSsmlAnnouncement:(nonnull NSString *)ssmlAnnouncement
                                    announcement:(nonnull NSString *)announcement;

@property (nonatomic, readonly, nonnull, copy) NSString * ssmlAnnouncement;
@property (nonatomic, readonly, nonnull, copy) NSString * announcement;
@end
