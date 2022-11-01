import CoreLocation
import MapboxCoreNavigation
import XCTest
import TestHelper

@available(*, deprecated)
final class PredictiveCacheOptionsTests: TestCase {

    private var cacheOptions: PredictiveCacheOptions!

    override func setUp() {
        super.setUp()

        cacheOptions = .init()
        cacheOptions.predictiveCacheMapsOptions.maximumConcurrentRequests = 3
        cacheOptions.predictiveCacheMapsOptions.locationOptions.currentLocationRadius = 100
        cacheOptions.predictiveCacheMapsOptions.locationOptions.destinationLocationRadius = 10
        cacheOptions.predictiveCacheNavigationOptions.locationOptions.currentLocationRadius = 200
        cacheOptions.predictiveCacheNavigationOptions.locationOptions.destinationLocationRadius = 20
    }

    func testSetCurrentLocationRadius() {
        let newLocationRadius: CLLocationDistance = 300
        cacheOptions.currentLocationRadius = newLocationRadius
        XCTAssertEqual(cacheOptions.currentLocationRadius, newLocationRadius)
        XCTAssertEqual(cacheOptions.predictiveCacheMapsOptions.locationOptions.currentLocationRadius, newLocationRadius)
        XCTAssertEqual(cacheOptions.predictiveCacheNavigationOptions.locationOptions.currentLocationRadius, newLocationRadius)
    }

    func testSetDestinationLocationRadius() {
        let newLocationRadius: CLLocationDistance = 300
        cacheOptions.destinationLocationRadius = newLocationRadius
        XCTAssertEqual(cacheOptions.destinationLocationRadius, newLocationRadius)
        XCTAssertEqual(cacheOptions.predictiveCacheMapsOptions.locationOptions.destinationLocationRadius, newLocationRadius)
        XCTAssertEqual(cacheOptions.predictiveCacheNavigationOptions.locationOptions.destinationLocationRadius, newLocationRadius)
    }

    func testSetMaximumConcurrentRequests() {
        let maximumConcurrentRequests: UInt32 = 10
        cacheOptions.maximumConcurrentRequests = maximumConcurrentRequests
        XCTAssertEqual(cacheOptions.maximumConcurrentRequests, maximumConcurrentRequests)
        XCTAssertEqual(cacheOptions.predictiveCacheMapsOptions.maximumConcurrentRequests, maximumConcurrentRequests)
    }

}
