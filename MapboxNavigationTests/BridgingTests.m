#import <XCTest/XCTest.h>
@import MapboxNavigation;
@import MapboxCoreNavigation;
@import TestHelper;

@interface BridgingTests : XCTestCase <MBVoiceControllerDelegate, MBNavigationMapViewDelegate>

@end

@implementation BridgingTests

- (void)testNavigationOptions {
    MBNavigationOptions *options = [MBNavigationOptions navigationOptions];
    XCTAssertNotNil(options);
}

- (void)testRouteVoiceController {
    MBRoute *route = [MBFixture routeFromJSONFileName:@"routeWithInstructions"];
    MBNavigationService *service = [[MBNavigationService alloc] initWithRoute:route
                                                                   directions:nil
                                                               locationSource:nil
                                                            eventsManagerType:nil
                                                                   simulating:MBNavigationSimulationOptionsNever
                                                                   routerType:nil];
    
    MBRouteVoiceController *voiceController = [[MBRouteVoiceController alloc] initWithNavigationService:service];
    voiceController.voiceControllerDelegate = self;
}

- (void)testNavigationMapView {
    MBNavigationMapView *mapView = nil;
    mapView.navigationMapViewDelegate = self;
}

@end
