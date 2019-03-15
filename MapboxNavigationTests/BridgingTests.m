#import <XCTest/XCTest.h>
@import MapboxNavigation;

@interface BridgingTests : XCTestCase

@end

@implementation BridgingTests

- (void)testNavigationOptions {
    MBNavigationOptions *options = [MBNavigationOptions navigationOptions];
    XCTAssertNotNil(options);
}

@end
