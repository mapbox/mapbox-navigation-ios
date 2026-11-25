#import "FakeCPInterfaceController.h"

@interface FakeCPInterfaceController ()
@property (nonatomic, strong, readonly) NSString *context;
@property (nonatomic, strong) NSMutableArray<CPTemplate *> *templateStack;
@property (nonatomic, readwrite) NSUInteger pushTemplateCallCount;
@property (nonatomic, readwrite) NSUInteger popTemplateCallCount;
@property (nonatomic, readwrite) NSUInteger popToRootTemplateCallCount;
@property (nonatomic, readwrite) NSUInteger popToTemplateCallCount;
@property (nonatomic, strong, nullable) CPTemplate *pendingPushTemplate;
@property (nonatomic, copy, nullable) void (^pendingPushCompletion)(BOOL, NSError * _Nullable);
@property (nonatomic) BOOL pendingPopToRootTemplate;
@property (nonatomic, copy, nullable) void (^pendingPopToRootCompletion)(BOOL, NSError * _Nullable);
@property (nonatomic, strong, nullable) CPTemplate *pendingPopTargetTemplate;
@property (nonatomic, copy, nullable) void (^pendingPopToTemplateCompletion)(BOOL, NSError * _Nullable);
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
    self.pushTemplateCallCount += 1;
    if (self.nextPushTemplateError != nil) {
        NSError *error = self.nextPushTemplateError;
        self.nextPushTemplateError = nil;
        if (completion != nil) {
            completion(false, error);
        }
        return;
    }
    if (self.suspendNextPushTemplateCompletion) {
        self.suspendNextPushTemplateCompletion = false;
        self.pendingPushTemplate = templateToPush;
        self.pendingPushCompletion = completion;
        return;
    }

    [self.templateStack addObject:templateToPush];
    if (completion != nil) {
        completion(true, nil);
    }
}

- (void)popTemplateAnimated:(BOOL)animated completion:(nullable void (^)(BOOL, NSError * _Nullable))completion {
    self.popTemplateCallCount += 1;

    if (self.templateStack.count > 1) {
        [self.templateStack removeLastObject];
    }
    if (completion != nil) {
        completion(true, nil);
    }
}

- (void)popToRootTemplateAnimated:(BOOL)animated completion:(nullable void (^)(BOOL, NSError * _Nullable))completion {
    self.popToRootTemplateCallCount += 1;
    if (self.nextPopToRootTemplateError != nil) {
        NSError *error = self.nextPopToRootTemplateError;
        self.nextPopToRootTemplateError = nil;
        if (completion != nil) {
            completion(false, error);
        }
        return;
    }
    if (self.suspendNextPopToRootTemplateCompletion) {
        self.suspendNextPopToRootTemplateCompletion = false;
        self.pendingPopToRootTemplate = true;
        self.pendingPopToRootCompletion = completion;
        return;
    }

    while (self.templateStack.count > 1) {
        [self.templateStack removeLastObject];
    }
    if (completion != nil) {
        completion(true, nil);
    }
}

- (void)popToTemplate:(CPTemplate *)targetTemplate animated:(BOOL)animated completion:(nullable void (^)(BOOL, NSError * _Nullable))completion {
    self.popToTemplateCallCount += 1;
    if (self.nextPopToTemplateError != nil) {
        NSError *error = self.nextPopToTemplateError;
        self.nextPopToTemplateError = nil;
        if (completion != nil) {
            completion(false, error);
        }
        return;
    }

    NSUInteger index = [self.templateStack indexOfObjectIdenticalTo:targetTemplate];
    if (index == NSNotFound) {
        if (completion != nil) {
            completion(false, [NSError errorWithDomain:@"FakeCPInterfaceController" code:1 userInfo:nil]);
        }
        return;
    }
    if (self.suspendNextPopToTemplateCompletion) {
        self.suspendNextPopToTemplateCompletion = false;
        self.pendingPopTargetTemplate = targetTemplate;
        self.pendingPopToTemplateCompletion = completion;
        return;
    }

    while (self.templateStack.count > index + 1) {
        [self.templateStack removeLastObject];
    }
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
    [self.templateStack removeAllObjects];
    [self.templateStack addObject:rootTemplate];
    if (completion != nil) {
        completion(true, nil);
    }
}

- (BOOL)hasPendingPushTemplate {
    return self.pendingPushTemplate != nil;
}

- (BOOL)hasPendingPopToRootTemplate {
    return self.pendingPopToRootTemplate;
}

- (BOOL)hasPendingPopToTemplate {
    return self.pendingPopTargetTemplate != nil;
}

- (void)completePendingPushTemplate {
    [self completePendingPushTemplateWithError:nil];
}

- (void)completePendingPushTemplateWithError:(nullable NSError *)error {
    CPTemplate *template = self.pendingPushTemplate;
    void (^completion)(BOOL, NSError * _Nullable) = self.pendingPushCompletion;
    self.pendingPushTemplate = nil;
    self.pendingPushCompletion = nil;
    if (template == nil) {
        return;
    }

    if (error != nil) {
        if (completion != nil) {
            completion(false, error);
        }
        return;
    }
    [self.templateStack addObject:template];
    if (completion != nil) {
        completion(true, nil);
    }
}

- (void)completePendingPopToRootTemplate {
    if (!self.pendingPopToRootTemplate) {
        return;
    }

    void (^completion)(BOOL, NSError * _Nullable) = self.pendingPopToRootCompletion;
    self.pendingPopToRootTemplate = false;
    self.pendingPopToRootCompletion = nil;
    while (self.templateStack.count > 1) {
        [self.templateStack removeLastObject];
    }
    if (completion != nil) {
        completion(true, nil);
    }
}

- (void)completePendingPopToTemplate {
    CPTemplate *targetTemplate = self.pendingPopTargetTemplate;
    void (^completion)(BOOL, NSError * _Nullable) = self.pendingPopToTemplateCompletion;
    self.pendingPopTargetTemplate = nil;
    self.pendingPopToTemplateCompletion = nil;
    if (targetTemplate == nil) {
        return;
    }

    NSUInteger index = [self.templateStack indexOfObjectIdenticalTo:targetTemplate];
    if (index == NSNotFound) {
        if (completion != nil) {
            completion(false, [NSError errorWithDomain:@"FakeCPInterfaceController" code:1 userInfo:nil]);
        }
        return;
    }
    while (self.templateStack.count > index + 1) {
        [self.templateStack removeLastObject];
    }
    if (completion != nil) {
        completion(true, nil);
    }
}

@end
