import XCTest
@testable import MapboxNavigation
import MapboxDirections

class NavigationMapViewTests: XCTestCase {
    
    let coordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 2),
        CLLocationCoordinate2D(latitude: 3, longitude: 3),
        CLLocationCoordinate2D(latitude: 4, longitude: 4),
        CLLocationCoordinate2D(latitude: 5, longitude: 5),
        ]
    
    func testNavigationMapViewCombineWithSimilarCongestions() {
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        
        let congestionSegments = navigationMapView.combine(coordinates, with: [
            .low,
            .low,
            .low,
            .low,
            .low
            ])
        
        XCTAssertEqual(congestionSegments.count, 1)
        XCTAssertEqual(congestionSegments[0].0.count, 10)
        XCTAssertEqual(congestionSegments[0].1, .low)
    }
    
    func testNavigationMapViewCombineWithDissimilarCongestions() {
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        
        let congestionSegmentsSevere = navigationMapView.combine(coordinates, with: [
            .low,
            .low,
            .severe,
            .low,
            .low
            ])
        
        // The severe breaks the trend of .low.
        // Any time the current congestion level is different than the previous segment, we have to create a new congestion segment.
        XCTAssertEqual(congestionSegmentsSevere.count, 3)
        
        XCTAssertEqual(congestionSegmentsSevere[0].0.count, 4)
        XCTAssertEqual(congestionSegmentsSevere[1].0.count, 2)
        XCTAssertEqual(congestionSegmentsSevere[2].0.count, 4)
        
        XCTAssertEqual(congestionSegmentsSevere[0].1, .low)
        XCTAssertEqual(congestionSegmentsSevere[1].1, .severe)
        XCTAssertEqual(congestionSegmentsSevere[2].1, .low)
    }
}
