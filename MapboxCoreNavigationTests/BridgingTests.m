#import <XCTest/XCTest.h>
#import "MapboxCoreNavigationTests-Swift.h"
@import Mapbox;
@import MapboxCoreNavigation;
@import MapboxDirections;
@import TestHelper;
@import MapKit;

@interface BridgingTests : XCTestCase
@property (nonatomic) MBRouteController *routeController;
@property (nonatomic) CLLocationManager *locationManager;
@end

@implementation BridgingTests
    
- (void)setUp {
    [super setUp];
}
    
- (void)testUpdateRoute {
    NSDictionary *response = [MBFixture JSONFromFileNamedWithName:@"routeWithInstructions"];
    NSDictionary *routeDict = response[@"routes"][0];
    MBWaypoint *wp1 = [[MBWaypoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(37.795042, -122.413165) coordinateAccuracy:0 name:@"wp1"];
    MBWaypoint *wp2 = [[MBWaypoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(37.7727, -122.433378) coordinateAccuracy:0 name:@"wp2"];
    NSArray<MBWaypoint *> *waypoints = @[wp1, wp2];
    MBNavigationRouteOptions *options = [[MBNavigationRouteOptions alloc] initWithWaypoints:waypoints profileIdentifier:MBDirectionsProfileIdentifierAutomobileAvoidingTraffic];
    MBRoute *route = [[MBRoute alloc] initWithJSON:routeDict waypoints:waypoints routeOptions:options];
    route.accessToken = @"garbage";
    XCTAssertNotNil(route);

    
    MBDirectionsSpy *directions = [[MBDirectionsSpy alloc] initWithAccessToken:@"garbage" host:nil];
    MBNavigationLocationManager *locationManager = [[MBNavigationLocationManager alloc] init];
    _locationManager = locationManager;
    _routeController = [[MBRouteController alloc] initWithRoute:route directions:directions dataSource:locationManager];
    XCTAssertNotNil(_routeController);
    
    XCTestExpectation *expectation = [self expectationForNotification:MBRouteControllerDidRerouteNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    _routeController.routeProgress = [[MBRouteProgress alloc] initWithRoute:route legIndex:0 spokenInstructionIndex:0];
    [self waitForExpectations:@[expectation] timeout:5];
}

// This test is excluded from the test suite. We are just verifying that offline routing bridges to Obj-C at compile time.
- (void)testOfflineRouting {
    [[[MBDirections sharedDirections] fetchAvailableOfflineVersionsWithCompletionHandler:^(NSArray<NSString *> * _Nullable versions, NSError * _Nullable error) {
        
        MBCoordinateBounds *bounds = [[MBCoordinateBounds alloc] initWithNorthWest:CLLocationCoordinate2DMake(0, 0) southEast:CLLocationCoordinate2DMake(1, 1)];
        
        [[[MBDirections sharedDirections] downloadTilesIn:bounds version:versions.firstObject session:nil completionHandler:^(NSURL * _Nullable url, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSURL *outputDirectoryURL = [[NSBundle mapboxCoreNavigation] suggestedTileURLWithVersion:versions.firstObject];
            
            [MBNavigationDirections unpackTilePackAtURL:url outputDirectoryURL:outputDirectoryURL progressHandler:^(uint64_t totalBytes, uint64_t bytesRemaining) {
                // Show unpacking progress
            } completionHandler:^(uint64_t numberOfTiles, NSError * _Nullable error) {
                // Dismiss UI
            }];
            
        }] resume];
    }] resume];
    
    MBNavigationRouteOptions *options = [[MBNavigationRouteOptions alloc] initWithLocations:@[] profileIdentifier:MBDirectionsProfileIdentifierCycling];
    
    MBNavigationDirections *directions = nil;
    
    [directions calculateDirectionsWithOptions:options offline:YES completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints, NSArray<MBRoute *> * _Nullable routes, NSError * _Nullable error) {
        
    }];
    
    NSURL *url = [NSURL URLWithString:@""];
    [directions configureRouterWithTilesURL:url translationsURL:url completionHandler:^(uint64_t numberOfTiles) {
        
    }];
}
    
@end

