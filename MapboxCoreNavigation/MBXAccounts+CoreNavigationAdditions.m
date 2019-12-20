#import "MBXAccounts+CoreNavigationAdditions.h"

@implementation MBXAccounts (CoreNavigationAdditions)

+ (void)load {
    NSString *billingMethodValue = [NSBundle.mainBundle objectForInfoDictionaryKey:@"MBXNavigationBillingMethod"];
    MBXAccountsSKUID skuIdentifier = MBXAccountsSKUIDNavigationSession;
    if ([billingMethodValue isEqualToString:@"mau"]) {
        skuIdentifier = MBXAccountsSKUIDNavigationUser;
    }
    [MBXAccounts activateSKUID:skuIdentifier];
}

@end
