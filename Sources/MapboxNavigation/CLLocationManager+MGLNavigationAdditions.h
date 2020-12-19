#import <CoreLocation/CoreLocation.h>

// iOS 13 and below lack a CLAccuracyAuthorization enumeration, so this compatibility shim enables PassiveLocationManager.accuracyAuthorization to be declared with a consistent type across iOS 13 and 14.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 140000
typedef NS_ENUM(NSInteger, MBNavigationAccuracyAuthorization) {
    MBNavigationAccuracyAuthorizationFullAccuracy,
    MBNavigationAccuracyAuthorizationReducedAccuracy,
};
#else
typedef CLAccuracyAuthorization MBNavigationAccuracyAuthorization;
#endif
