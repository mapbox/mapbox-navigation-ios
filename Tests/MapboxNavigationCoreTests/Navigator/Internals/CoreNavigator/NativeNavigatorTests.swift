import _MapboxNavigationTestHelpers
import CoreLocation
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class NativeNavigatorTests: XCTestCase {
    var navigator: NativeNavigator!
    var testLocation: CLLocation!

    override func setUp() async throws {
        try? await super.setUp()

        testLocation = CLLocation(latitude: 1.0, longitude: 2.0)
        let nativeHandlersFactory = NativeHandlersFactory(
            tileStorePath: "tile",
            apiConfiguration: .mock(),
            tilesVersion: "",
            datasetProfileIdentifier: .automobile,
            liveIncidentsOptions: nil,
            navigatorPredictionInterval: nil,
            utilizeSensorData: true,
            historyDirectoryURL: nil,
            initialManeuverAvoidanceRadius: 8,
            locale: .current,
            rerouteStrategyForMatchRoute: .rerouteDisabled
        )
        navigator = await .init(with: .init(
            credentials: .mock(),
            nativeHandlersFactory: nativeHandlersFactory,
            routingConfig: .init(),
            predictiveCacheManager: nil
        ))
    }

    @MainActor
    func testUpdateLocation() {
        XCTAssertNil(navigator.rawLocation)

        navigator.updateLocation(testLocation) { _ in }
        XCTAssertEqual(navigator.rawLocation, testLocation)
    }
}
