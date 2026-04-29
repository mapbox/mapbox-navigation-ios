@testable import MapboxDirections
import Turf
import XCTest

class QuickLookTests: XCTestCase {
    func testQuickLookURL() {
        let lineString = LineString([
            LocationCoordinate2D(latitude: 0, longitude: 0),
            LocationCoordinate2D(latitude: 1, longitude: 1),
        ])
        XCTAssertEqual(
            debugQuickLookURL(illustrating: lineString, accessToken: BogusToken),
            URL(
                string: "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/path-10+3802DA-0.6(%3F%3F_ibE_ibE)/auto/680x360@2x?before_layer=building-number-label&access_token=\(BogusToken)"
            )
        )
        XCTAssertEqual(
            debugQuickLookURL(
                illustrating: lineString,
                profileIdentifier: .automobileAvoidingTraffic,
                accessToken: BogusToken
            ),
            URL(
                string: "https://api.mapbox.com/styles/v1/mapbox/navigation-preview-day-v4/static/path-10+3802DA-0.6(%3F%3F_ibE_ibE)/auto/680x360@2x?before_layer=waterway-label&access_token=\(BogusToken)"
            )
        )
        XCTAssertEqual(
            debugQuickLookURL(illustrating: lineString, profileIdentifier: .cycling, accessToken: BogusToken),
            URL(
                string: "https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/path-10+3802DA-0.6(%3F%3F_ibE_ibE)/auto/680x360@2x?before_layer=contour-label&access_token=\(BogusToken)"
            )
        )
    }
}
