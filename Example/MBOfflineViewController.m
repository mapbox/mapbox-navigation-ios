#import "MBOfflineViewController.h"

@import Mapbox;
@import MapboxDirections;
@import MapboxCoreNavigation;
@import MapboxNavigation;

@interface OfflineNavigationViewController ()

@property (nonatomic) MBNavigationDirections *navigationDirections;
@property (nonatomic) MBNavigationService *navigationService;

@end

@implementation OfflineNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offlinePackProgressDidChange:) name:MGLOfflinePackProgressChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offlinePackDidReceiveError:) name:MGLOfflinePackErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offlinePackDidReceiveMaximumAllowedMapboxTiles:) name:MGLOfflinePackMaximumMapboxTilesReachedNotification object:nil];
    
    self.navigationDirections = [[MBNavigationDirections alloc] initWithAccessToken:[MBDirections sharedDirections].accessToken host:[MBDirections sharedDirections].apiEndpoint.host];
    
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(39.00665, -84.73858);
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(39.13991, -84.41586);
    
    [self downloadMapTilesInCoordinateBounds:MGLCoordinateBoundsMake(southWest, northEast)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)downloadMapTilesInCoordinateBounds:(MGLCoordinateBounds)coordinateBounds {
    // TODO: Also download [MGLStyle navigationGuidanceNightStyleURL].
    id<MGLOfflineRegion> offlineRegion = [[MGLTilePyramidOfflineRegion alloc] initWithStyleURL:[MGLStyle navigationGuidanceDayStyleURL] bounds:coordinateBounds fromZoomLevel:14 toZoomLevel:16];
    NSDictionary *userInfo = @{@"name": @"Cincinnati"};
    NSData *context = [NSKeyedArchiver archivedDataWithRootObject:userInfo];
    
    [[MGLOfflineStorage sharedOfflineStorage] addPackForRegion:offlineRegion withContext:context completionHandler:^(MGLOfflinePack *pack, NSError *error) {
        NSAssert(!error, @"Unable to add offline pack to the map’s storage: %@", error);
        [pack resume];
    }];
}

- (void)offlinePackProgressDidChange:(NSNotification *)notification {
    MGLOfflinePack *pack = notification.object;
    NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:pack.context];
    
    MGLOfflinePackProgress progress = pack.progress;
    uint64_t completedResources = progress.countOfResourcesCompleted;
    uint64_t expectedResources = progress.countOfResourcesExpected;
    
    if (completedResources == expectedResources) {
        NSString *byteCount = [NSByteCountFormatter stringFromByteCount:progress.countOfBytesCompleted countStyle:NSByteCountFormatterCountStyleMemory];
        NSLog(@"Offline pack “%@” completed: %@, %llu resources", userInfo[@"name"], byteCount, completedResources);
        
        [self offlinePackDidComplete:pack];
    } else {
        float progressPercentage = (float)completedResources / expectedResources;
        NSLog(@"Offline pack “%@” has %llu of %llu resources — %.2f%%.", userInfo[@"name"], completedResources, expectedResources, progressPercentage * 100);
    }
}

- (void)offlinePackDidComplete:(MGLOfflinePack *)pack {
    MGLTilePyramidOfflineRegion *offlineRegion = (MGLTilePyramidOfflineRegion *)pack.region;
    MGLCoordinateBounds mapCoordinateBounds = offlineRegion.bounds;
    MBCoordinateBounds *coordinateBounds = [[MBCoordinateBounds alloc] initWithCoordinates:@[[NSValue valueWithMGLCoordinate:mapCoordinateBounds.sw], [NSValue valueWithMGLCoordinate:mapCoordinateBounds.ne]]];
    [self downloadRoutingTilesInCoordinateBounds:coordinateBounds withCompletionHandler:^{
        MBWaypoint *unionTerminal = [[MBWaypoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(39.10992, -84.53762) coordinateAccuracy:-1 name:@"Union Terminal"];
        MBWaypoint *airport = [[MBWaypoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(39.05008, -84.67105) coordinateAccuracy:-1 name:@"CVG"];
        [self navigateBetweenWaypoints:@[unionTerminal, airport]];
    }];
}

- (void)offlinePackDidReceiveError:(NSNotification *)notification {
    MGLOfflinePack *pack = notification.object;
    NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:pack.context];
    NSError *error = notification.userInfo[MGLOfflinePackUserInfoKeyError];
    NSLog(@"Offline pack “%@” received error: %@", userInfo[@"name"], error.localizedFailureReason);
}

- (void)offlinePackDidReceiveMaximumAllowedMapboxTiles:(NSNotification *)notification {
    MGLOfflinePack *pack = notification.object;
    NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:pack.context];
    uint64_t maximumCount = [notification.userInfo[MGLOfflinePackUserInfoKeyMaximumCount] unsignedLongLongValue];
    NSLog(@"Offline pack “%@” reached limit of %llu tiles.", userInfo[@"name"], maximumCount);
}

- (void)downloadRoutingTilesInCoordinateBounds:(MBCoordinateBounds *)coordinateBounds withCompletionHandler:(void (^)(void))completion {
    NSLog(@"Fetching versions…");
    
    [[self.navigationDirections fetchAvailableOfflineVersionsWithCompletionHandler:^(NSArray<NSString *> * _Nullable versions, NSError * _Nullable error) {
        NSAssert(versions.count, @"No routing tile versions are available for download. Please try again later.");
        NSString *version = versions.firstObject;
        
        NSLog(@"Downloading tiles…");
        
        [[self.navigationDirections downloadTilesIn:coordinateBounds version:version session:nil completionHandler:^(NSURL * _Nullable url, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSAssert(url, @"Unable to locate temporary file.");
            NSAssert(response, @"No response from server.");
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSAssert(httpResponse.statusCode != 402, @"Before you can fetch routing tiles you must obtain an enterprise access token.");
            NSAssert(httpResponse.statusCode != 422, @"The bounding box you have specified is too large. Please select a smaller box and try again.");
            
            NSURL *outputDirectoryURL = [[NSBundle mapboxCoreNavigation] suggestedTileURLWithVersion:version];
            [[NSFileManager defaultManager] createDirectoryAtURL:outputDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
            
            [MBNavigationDirections unpackTilePackAtURL:url outputDirectoryURL:outputDirectoryURL progressHandler:^(uint64_t totalBytes, uint64_t bytesRemaining) {
                CGFloat progress = (CGFloat)bytesRemaining / (CGFloat)totalBytes;
                NSString *formattedProgress = [NSNumberFormatter localizedStringFromNumber:@(progress) numberStyle:NSNumberFormatterPercentStyle];
                NSLog(@"Unpacking… (%@)", formattedProgress);
            } completionHandler:^(uint64_t result, NSError * _Nullable error) {
                [self.navigationDirections configureRouterWithTilesURL:outputDirectoryURL translationsURL:nil completionHandler:^(uint64_t numberOfTiles) {
                    NSLog(@"Router configured with %llu tile(s).", numberOfTiles);
                    
                    completion();
                }];
            }];
        }] resume];
    }] resume];
}

- (void)navigateBetweenWaypoints:(NSArray<MBWaypoint *> *)waypoints {
    MBNavigationRouteOptions *routeOptions = [[MBNavigationRouteOptions alloc] initWithWaypoints:waypoints profileIdentifier:nil];
    
    [self.navigationDirections calculateDirectionsWithOptions:routeOptions offline:YES completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints, NSArray<MBRoute *> * _Nullable routes, NSError * _Nullable error) {
        NSAssert(routes.count, @"No routes found.");
        [self navigateAlongRoute:routes.firstObject];
    }];
}

- (void)navigateAlongRoute:(MBRoute *)route {
    self.navigationService = [[MBNavigationService alloc] initWithRoute:route directions:self.navigationDirections locationSource:nil eventsManagerType:nil simulating:MBNavigationSimulationOptionsAlways routerType:nil];
    
    MBNavigationOptions *options = [[MBNavigationOptions alloc] init];
    options.navigationService = self.navigationService;
    
    MBNavigationViewController *controller = [[MBNavigationViewController alloc] initWithRoute:route options:options];
    [self presentViewController:controller animated:YES completion:nil];
}

@end
