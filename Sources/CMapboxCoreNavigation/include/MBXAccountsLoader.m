#import <Foundation/Foundation.h>

@interface MBXAccountsLoader : NSObject
@end

@implementation MBXAccountsLoader

+ (void)load {
    Class MBXAccounts = NSClassFromString(@"MBXAccounts");
    if ([MBXAccounts respondsToSelector:NSSelectorFromString(@"serviceSkuToken")]) {
        (void)[MBXAccounts valueForKey:@"serviceSkuToken"];
    }
}

@end
