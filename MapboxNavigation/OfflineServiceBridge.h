#import <Foundation/Foundation.h>

@import MapboxDirections;
@import Mapbox;

@interface OfflineServiceBridge : NSObject
+ (void)downloadTilesWithPolyline:(nonnull MGLPolyline *)polyline name:(nonnull NSString*)name style:(nonnull MGLStyle*)style minimumZoomLevel:(NSInteger)minimum maximumZoomLevel:(NSInteger)maximum;
@end

