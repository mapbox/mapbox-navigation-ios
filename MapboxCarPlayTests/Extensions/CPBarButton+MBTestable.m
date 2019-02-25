#import "CPBarButton+MBTestable.h"
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000

@interface CPBarButton (MBTestableInternal)

- (instancetype)init_original_initWithType:(CPBarButtonType)type handler:(void (^)(CPBarButton * _Nonnull))handler;

@end


static char *HandlerKey;

@implementation CPBarButton (MBTestable)

+ (void)load {
    Method originalMethod = class_getInstanceMethod(self, @selector(initWithType:handler:));
    class_addMethod(self, @selector(init_original_initWithType:handler:), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));

    Method newMethod = class_getInstanceMethod(self, @selector(initWithType:handlerToKeep:));
    class_replaceMethod(self, @selector(initWithType:handler:), method_getImplementation(newMethod), method_getTypeEncoding(newMethod));

}

- (instancetype)initWithType:(CPBarButtonType)type handlerToKeep:(void (^ _Nullable)(CPBarButton *barButton))handler {
    self = [self init_original_initWithType:type handler:handler];
    if (self) {
        [self setHandler:handler];
    }
    return self;
}

- (void(^)(CPBarButton *))handler {
    return objc_getAssociatedObject(self, &HandlerKey);
}

- (void)setHandler:(void(^)(CPBarButton *))handler {
    objc_setAssociatedObject(self, &HandlerKey, handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

#endif
