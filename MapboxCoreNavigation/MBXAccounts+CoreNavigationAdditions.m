#import "MBXAccounts+CoreNavigationAdditions.h"

@implementation MBXAccounts (CoreNavigationAdditions)

+ (void)load {
    [MBXAccounts activateSKUID:MBXAccountsSKUIDNavigationSession];
}

@end
