import MapboxMaps
@testable import MapboxNavigationUIKit
import XCTest

final class CarPlayMapOverlayConfigurationTests: XCTestCase {
    func testCarPlayOverlayConfigurationSizes() {
        XCTAssertEqual(CarPlayUtilities.compactRouteLineWidthMultiplier, 0.7)
        XCTAssertEqual(Puck2DConfiguration.carPlayCompact.scale, .constant(0.6))
        XCTAssertEqual(Puck2DConfiguration.carPlayHD.scale, .constant(0.8))
        XCTAssertEqual(
            Puck3DConfiguration.carPlayCompact.modelScale,
            .constant([1.0, 1.0, 1.0])
        )
        XCTAssertEqual(
            Puck3DConfiguration.carPlayHD.modelScale,
            .constant([1.1, 1.1, 1.1])
        )
    }
}
