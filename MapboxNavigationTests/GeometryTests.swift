import Foundation
import XCTest
import CoreLocation
@testable import MapboxNavigation

class GeometryTests: XCTestCase {
    let point1 = CLLocationCoordinate2D(latitude: 35, longitude: 35)
    let point2 = CLLocationCoordinate2D(latitude: -10, longitude: -10)
    let point3 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
    let point4 = CLLocationCoordinate2D(latitude: 40, longitude: 40)
    let point5 = CLLocationCoordinate2D(latitude: 30, longitude: 30)
    
    func testClosestCoordinate() {
        let line = [point3, point4]
        
        let closestPoint = closestCoordinate(on: line, to: point1)
        XCTAssertEqual(closestPoint!.coordinate, point4)
    }
    
    func testPolyline() {
        let line = [point3, point4]
        
        let a = polyline(along: line)
        XCTAssertEqual(a.count, 2)
        XCTAssertEqual(a.first, line.first)
        XCTAssertEqual(a.last, line.last)
        
        let b = polyline(along: line, from: CLLocationCoordinate2D(latitude: 25, longitude: 25), to: CLLocationCoordinate2D(latitude: 40, longitude: 40))
        XCTAssertEqual(b.count, 2)
        XCTAssertEqual(b.first, point3)
        XCTAssertEqual(b.last, point4)
        
        let c = polyline(along: line, within: 20, of: point1)
        XCTAssertEqual(c.count, 2)
        XCTAssertEqual(c.first, point4)
        XCTAssertEqual(c.last, point4)
    }
    
    func testDistance() {
        let line = [point3, point4]
        
        let a = distance(along: line)
        XCTAssertEqual(round(a), 2928304)
        
        let b = distance(along: line, from: CLLocationCoordinate2D(latitude: 30, longitude: 30), to: CLLocationCoordinate2D(latitude: 40, longitude: 40))
        XCTAssertEqual(round(b), 1435783)
    }
    
    func testWrap() {
        let a = wrap(380, min: 0, max: 360)
        XCTAssertEqual(a, 20)
        
        let b = wrap(-30, min: 0, max: 360)
        XCTAssertEqual(b, 330)
    }
    
    func testCLLocationCoordinate2() {
        let a = point1.direction(to: point2)
        XCTAssertEqual(round(a), -128)
        
        let b = point1.coordinate(at: 20, facing: 20)
        XCTAssertEqual(round(b.latitude), 35)
        XCTAssertEqual(round(b.longitude), 35)
    }
    
    func testIntersection() {
        let a = intersection((CLLocationCoordinate2D(latitude: 20, longitude: 20), CLLocationCoordinate2D(latitude: 40, longitude: 40)), (CLLocationCoordinate2D(latitude: 20, longitude: 40), CLLocationCoordinate2D(latitude: 40, longitude: 20)))
        XCTAssertEqual(a, point5)
    }
    
    func testCLLocationDegrees() {
        let degree: CLLocationDegrees = 100
        let a = degree.toRadians()
        XCTAssertEqual(round(a), 2)
        
        let radian: LocationRadians = 4
        let b = radian.toDegrees()
        XCTAssertEqual(round(b), 229)
    }
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
