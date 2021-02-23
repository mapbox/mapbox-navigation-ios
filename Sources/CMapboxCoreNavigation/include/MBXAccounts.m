#import "MBXAccounts.h"

static NSString * const MBXNavigationBillingMethodUser = @"user";
static NSString * const MBXNavigationBillingMethodRequest = @"request";

@implementation MBXAccounts

+ (void)load {
    (void)[MBXAccounts serviceSkuToken];
}

+ (nullable NSString *)serviceSkuToken {
    NSString *billingMethodValue = [NSBundle.mainBundle objectForInfoDictionaryKey:@"MBXNavigationBillingMethod"];
    if (!billingMethodValue.length || [billingMethodValue isEqualToString:MBXNavigationBillingMethodUser]) {
        return [MBXTokenGenerator getSKUTokenForIdentifier:MBXSKUIdentifierNavigationMAUS withError:NULL];
    } else if (![billingMethodValue isEqualToString:MBXNavigationBillingMethodRequest]) {
        // Billing method is not the default in the absence of a SKU ID.
        [NSException raise:@"MBXInvalidNavigationBillingMethod"
                    format:@"Unrecognized billing method %@. Valid billing methods are: %@, %@.",
         billingMethodValue, MBXNavigationBillingMethodUser, MBXNavigationBillingMethodRequest];
    }
    return nil;
}

@end
