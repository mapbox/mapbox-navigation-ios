#import <XCTest/XCTest.h>
#import "MapboxCoreNavigationTests-Swift.h"
@import Mapbox;
@import MapboxCoreNavigation;
@import MapboxDirections;

@interface BridgingTests : XCTestCase
@property (nonatomic) MBRouteController *routeController;
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
    MBEventsManager *eventsManager = [[MBEventsManager alloc] init];
    eventsManager.manager = [[MBEventsManagerSpy alloc] init];
    
    MBDirectionsSpy *directions = [[MBDirectionsSpy alloc] initWithAccessToken:@"garbage" host:nil];
    MBNavigationLocationManager *locationManager = [[MBNavigationLocationManager alloc] init];
    _routeController = [[MBRouteController alloc] initWithRoute:route directions:directions locationManager:locationManager eventsManager:eventsManager];
    XCTAssertNotNil(_routeController);
    
    XCTestExpectation *expectation = [self expectationForNotification:MBRouteControllerDidRerouteNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    _routeController.routeProgress = [[MBRouteProgress alloc] initWithRoute:route legIndex:0 spokenInstructionIndex:0];
    [self waitForExpectations:@[expectation] timeout:5];
}
    
@end

