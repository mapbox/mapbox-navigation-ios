import Foundation
import XCTest
import CoreLocation
@testable import MapboxNavigation

class GeometryTests: XCTestCase {
    func testClosestCoordinate() {
        let point1 = CLLocationCoordinate2D(latitude: 35, longitude: 35)
        let point2 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        let point3 = CLLocationCoordinate2D(latitude: 40, longitude: 40)
        
        let line = [point2, point3]
        
        let closestPoint = closestCoordinate(on: line, to: point1)
        XCTAssertEqual(closestPoint!.coordinate, CLLocationCoordinate2D(latitude: 34.583587335233545, longitude: 34.583587335233545))
    }
    
    func testPolyline() {
        let point1 = CLLocationCoordinate2D(latitude: 35, longitude: 35)
        let point2 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        let point3 = CLLocationCoordinate2D(latitude: 40, longitude: 40)
        
        let line = [point2, point3]
        
        let a = polyline(along: line)
        XCTAssertEqual(a.count, 2)
        XCTAssertEqual(a.first, line.first)
        XCTAssertEqual(a.last, line.last)
        
        let b = polyline(along: line, from: CLLocationCoordinate2D(latitude: 25, longitude: 25), to: CLLocationCoordinate2D(latitude: 40, longitude: 40))
        XCTAssertEqual(b.count, 1)
        XCTAssertEqual(b.first, point3)
        
        let c = polyline(along: line, within: 20, of: point1)
        XCTAssertEqual(c.count, 2)
        XCTAssertEqual(c.first, CLLocationCoordinate2D(latitude: 34.583587335233545, longitude: 34.583587335233545))
        XCTAssertEqual(c.last, CLLocationCoordinate2D(latitude: 34.58373113960792, longitude: 34.583718442762901))
    }
    
    func testDistance() {
        let point1 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        let point2 = CLLocationCoordinate2D(latitude: 40, longitude: 40)
        let line = [point1, point2]
        
        let a = distance(along: line)
        XCTAssertEqualWithAccuracy(a, 2928304, accuracy: 1)
        
        let b = distance(along: line, from: CLLocationCoordinate2D(latitude: 30, longitude: 30), to: CLLocationCoordinate2D(latitude: 40, longitude: 40))
        XCTAssertEqualWithAccuracy(b, 1534694, accuracy: 1)
    }
    
    func testWrap() {
        let a = wrap(380, min: 0, max: 360)
        XCTAssertEqual(a, 20)
        
        let b = wrap(-30, min: 0, max: 360)
        XCTAssertEqual(b, 330)
    }
    
    func testCLLocationCoordinate2() {
        let point1 = CLLocationCoordinate2D(latitude: 35, longitude: 35)
        let point2 = CLLocationCoordinate2D(latitude: -10, longitude: -10)
        let a = point1.direction(to: point2)
        XCTAssertEqualWithAccuracy(a, -128, accuracy: 1)
        
        let b = point1.coordinate(at: 20, facing: 20)
        XCTAssertEqualWithAccuracy(b.latitude, 35, accuracy: 0.1)
        XCTAssertEqualWithAccuracy(b.longitude, 35, accuracy: 0.1)
    }
    
    func testIntersection() {
        let point1 = CLLocationCoordinate2D(latitude: 30, longitude: 30)
        let a = intersection((CLLocationCoordinate2D(latitude: 20, longitude: 20), CLLocationCoordinate2D(latitude: 40, longitude: 40)), (CLLocationCoordinate2D(latitude: 20, longitude: 40), CLLocationCoordinate2D(latitude: 40, longitude: 20)))
        XCTAssertEqual(a, point1)
    }
    
    func testCLLocationDegrees() {
        let degree: CLLocationDegrees = 100
        let a = degree.toRadians()
        XCTAssertEqualWithAccuracy(a, 2, accuracy: 1)
        
        let radian: LocationRadians = 4
        let b = radian.toDegrees()
        XCTAssertEqualWithAccuracy(b, 229, accuracy: 1)
    }
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
