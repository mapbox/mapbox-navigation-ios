#import "FakeCPTemplateApplicationScene.h"

@interface FakeCPTemplateApplicationScene ()
@property (nonatomic, strong, readonly) NSString *context;
@end

@implementation FakeCPTemplateApplicationScene

- (instancetype)initWithContext:(NSString *)context {
    /// This is only for tests, so we don't care about leaks.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    self = [super performSelector:NSSelectorFromString(@"init")];
#pragma clang diagnostic pop
    if (self) {
        _context = context;
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"CPTemplateApplicationSceneFake for %@", self.context];
}

@end
