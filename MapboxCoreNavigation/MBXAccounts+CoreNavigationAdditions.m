#import "MBXAccounts+CoreNavigationAdditions.h"

static NSString * const MBXNavigationBillingMethodUser = @"user";
static NSString * const MBXNavigationBillingMethodRequest = @"request";

@implementation MBXAccounts (CoreNavigationAdditions)

+ (void)load {
    NSString *billingMethodValue = [NSBundle.mainBundle objectForInfoDictionaryKey:@"MBXNavigationBillingMethod"];
    if (!billingMethodValue.length || [billingMethodValue isEqualToString:MBXNavigationBillingMethodUser]) {
        [MBXAccounts activateSKUID:MBXAccountsSKUIDNavigationUser];
    } else if ([billingMethodValue isEqualToString:MBXNavigationBillingMethodRequest]) {
        // This is the default in the absence of a SKU ID.
    } else {
        [NSException raise:@"MBXInvalidNavigationBillingMethod"
                    format:@"Unrecognized billing method %@. Valid billing methods are: %@, %@.",
         billingMethodValue, MBXNavigationBillingMethodUser, MBXNavigationBillingMethodRequest];
    }
}

@end
