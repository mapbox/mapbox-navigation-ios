import Foundation
import XCTest
import CoreLocation
@testable import MapboxNavigation

class GeometryTests: XCTestCase {
    let line = [CLLocationCoordinate2D(latitude: 20, longitude: 20), CLLocationCoordinate2D(latitude: 40, longitude: 40)]
    let point1 = CLLocationCoordinate2D(latitude: 35, longitude: 35)
    let point2 = CLLocationCoordinate2D(latitude: -10, longitude: -10)
    
    func testClosestCoordinate() {
        let closestPoint = closestCoordinate(on: line, to: point1)
        XCTAssertEqual(closestPoint?.coordinate.latitude, 40)
        XCTAssertEqual(closestPoint?.coordinate.longitude, 40)
    }
    
    func testPolyline() {
        let a = polyline(along: line)
        XCTAssertEqual(a.count, 2)
        XCTAssertEqual(a.first?.latitude, line.first?.latitude)
        XCTAssertEqual(a.first?.longitude, line.first?.longitude)
        XCTAssertEqual(a.last?.latitude, line[1].latitude)
        XCTAssertEqual(a.last?.longitude, line[1].longitude)
        
        let b = polyline(along: line, from: CLLocationCoordinate2D(latitude: 25, longitude: 25), to: CLLocationCoordinate2D(latitude: 40, longitude: 40))
        XCTAssertEqual(b.count, 2)
        XCTAssertEqual(b.first?.latitude, 20)
        XCTAssertEqual(b.first?.longitude, 20)
        XCTAssertEqual(b.last?.latitude, 40)
        XCTAssertEqual(b.last?.longitude, 40)
        
        let c = polyline(along: line, within: 20, of: point1)
        XCTAssertEqual(c.count, 2)
        XCTAssertEqual(c.first?.latitude, 40)
        XCTAssertEqual(c.first?.longitude, 40)
        XCTAssertEqual(c.last?.latitude, 40)
        XCTAssertEqual(c.last?.longitude, 40)
    }
    
    func testDistance() {
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
        XCTAssertEqual(a?.latitude, 30)
        XCTAssertEqual(a?.longitude, 30)
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
