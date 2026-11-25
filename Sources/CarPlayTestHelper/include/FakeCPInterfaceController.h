#import <Foundation/Foundation.h>
@import CarPlay;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(12.0))
@interface FakeCPInterfaceController : CPInterfaceController
/// A simple stub which allows for instantiation of a CPInterfaceController for testing.
/// CPInterfaceController cannot be instantiated directly. Properties which don't work in headless testing will need to
/// be overridden with test-specific mock functionality provided.
- (instancetype)initWithContext:(NSString *)context;

@property (nonatomic, strong, nullable) NSError *nextPushTemplateError;
@property (nonatomic, strong, nullable) NSError *nextPopToRootTemplateError;
@property (nonatomic, strong, nullable) NSError *nextPopToTemplateError;
@property (nonatomic) BOOL suspendNextPushTemplateCompletion;
@property (nonatomic) BOOL suspendNextPopToRootTemplateCompletion;
@property (nonatomic) BOOL suspendNextPopToTemplateCompletion;
@property (nonatomic, readonly) BOOL hasPendingPushTemplate;
@property (nonatomic, readonly) BOOL hasPendingPopToRootTemplate;
@property (nonatomic, readonly) BOOL hasPendingPopToTemplate;
@property (nonatomic, readonly) NSUInteger pushTemplateCallCount;
@property (nonatomic, readonly) NSUInteger popTemplateCallCount;
@property (nonatomic, readonly) NSUInteger popToRootTemplateCallCount;
@property (nonatomic, readonly) NSUInteger popToTemplateCallCount;
- (void)completePendingPushTemplate;
- (void)completePendingPushTemplateWithError:(nullable NSError *)error
    NS_SWIFT_NAME(completePendingPushTemplate(error:));
- (void)completePendingPopToRootTemplate;
- (void)completePendingPopToTemplate;
@end

NS_ASSUME_NONNULL_END
