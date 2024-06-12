#import "FakeCPInterfaceController.h"

@interface FakeCPInterfaceController()
@property (nonatomic, strong, readonly) NSString *context;
@property (nonatomic, strong) NSMutableArray<CPTemplate *> *templateStack;
@end

@implementation FakeCPInterfaceController {
    CPTemplate *_fakeRootTemplate;
}

- (instancetype)initWithContext:(NSString *)context {
    /// This is only for tests, so we don't care about leaks.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    self = [super performSelector:NSSelectorFromString(@"init")];
#pragma clang diagnostic pop
    if (self) {
        _context = context;
        _templateStack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"CPInterfaceControllerSpy for %@", self.context];
}

- (void)pushTemplate:(__kindof CPTemplate *)templateToPush animated:(BOOL)animated completion:(nullable void (^)(BOOL, NSError * _Nullable))completion {
    [self.templateStack addObject:templateToPush];
    if (completion != nil) {
        completion(true, nil);
    }
}

- (void)popTemplateAnimated:(BOOL)animated completion:(nullable void (^)(BOOL, NSError * _Nullable))completion {
    [self.templateStack removeLastObject];
    if (completion != nil) {
        completion(true, nil);
    }
}

- (CPTemplate *)topTemplate {
    return [self.templateStack lastObject];
}

- (NSArray<CPTemplate *> *)templates {
    return [self.templateStack copy];
}

- (__kindof CPTemplate *)rootTemplate {
    return _fakeRootTemplate;
}

- (void)setRootTemplate:(__kindof CPTemplate *)rootTemplate animated:(BOOL)animated completion:(void (^)(BOOL, NSError * _Nullable))completion {
    _fakeRootTemplate = rootTemplate;
    if (completion != nil) {
        completion(true, nil);
    }
}

@end
