#import "MBRouteController.h"
#import <CommonCrypto/CommonCrypto.h>

const NSNotificationName MBRouteControllerProgressDidChangeNotification             = @"RouteControllerProgressDidChange";
const NSNotificationName MBRouteControllerDidPassSpokenInstructionPointNotification = @"RouteControllerDidPassSpokenInstructionPoint";
const NSNotificationName MBRouteControllerDidPassVisualInstructionPointNotification = @"MBRouteControllerDidPassVisualInstructionPoint";
const NSNotificationName MBRouteControllerWillRerouteNotification                   = @"RouteControllerWillReroute";
const NSNotificationName MBRouteControllerDidRerouteNotification                    = @"RouteControllerDidReroute";
const NSNotificationName MBRouteControllerDidFailToRerouteNotification              = @"RouteControllerDidFailToReroute";

const MBRouteControllerNotificationUserInfoKey MBRouteControllerRouteProgressKey              = @"progress";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerLocationKey                   = @"location";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerRawLocationKey                = @"rawLocation";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerRoutingErrorKey               = @"error";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerIsProactiveKey                = @"RouteControllerDidFindFasterRoute";

NSString *const MBErrorDomain = @"ErrorDomain";

@implementation NSString (MD5)
- (NSString * _Nonnull)md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}
@end
