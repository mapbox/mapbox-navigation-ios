import Foundation
import XCTest
import CoreLocation
@testable import MapboxNavigation

let metersPerMile: CLLocationDistance = 1_609.344

class GeometryTests: XCTestCase {
    func testClosestCoordinate() {
        // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-point-on-line/test/test.js#L117-L118
        
        // turf-point-on-line - first point
        var line = [
            CLLocationCoordinate2D(latitude: 37.72003306385638, longitude: -122.45717525482178),
            CLLocationCoordinate2D(latitude: 37.718242366859215, longitude: -122.45717525482178),
        ]
        let point = CLLocationCoordinate2D(latitude: 37.72003306385638, longitude: -122.45717525482178)
        var snapped = closestCoordinate(on: line, to: point)
        XCTAssertEqual(point, snapped?.coordinate, "point on start should not move")
        
        // turf-point-on-line - points behind first point
        line = [
            CLLocationCoordinate2D(latitude: 37.72003306385638, longitude: -122.45717525482178),
            CLLocationCoordinate2D(latitude: 37.718242366859215, longitude: -122.45717525482178),
        ]
        var points = [
            CLLocationCoordinate2D(latitude: 37.72009306385638, longitude: -122.45717525482178),
            CLLocationCoordinate2D(latitude: 37.82009306385638, longitude: -122.45717525482178),
            CLLocationCoordinate2D(latitude: 37.72009306385638, longitude: -122.45716525482178),
            CLLocationCoordinate2D(latitude: 37.72009306385638, longitude: -122.45516525482178),
        ]
        for point in points {
            snapped = closestCoordinate(on: line, to: point)
            XCTAssertEqual(line.first, snapped?.coordinate, "point behind start should move to first vertex")
        }
        
        // turf-point-on-line - points in front of last point
        line = [
            CLLocationCoordinate2D(latitude: 37.72125936929241, longitude: -122.45616137981413),
            CLLocationCoordinate2D(latitude: 37.72003306385638, longitude: -122.45717525482178),
            CLLocationCoordinate2D(latitude: 37.718242366859215, longitude: -122.45717525482178),
        ]
        points = [
            CLLocationCoordinate2D(latitude: 37.71814052497085, longitude: -122.45696067810057),
            CLLocationCoordinate2D(latitude: 37.71813203814049, longitude: -122.4573630094528),
            CLLocationCoordinate2D(latitude: 37.71797927502795, longitude: -122.45730936527252),
            CLLocationCoordinate2D(latitude: 37.71704571582896, longitude: -122.45718061923981),
        ]
        for point in points {
            snapped = closestCoordinate(on: line, to: point)
            XCTAssertEqual(line.last, snapped?.coordinate, "point behind start should move to last vertex")
        }
        
        // turf-point-on-line - points on joints
        let lines = [
            [
                CLLocationCoordinate2D(latitude: 37.72125936929241, longitude: -122.45616137981413),
                CLLocationCoordinate2D(latitude: 37.72003306385638, longitude: -122.45717525482178),
                CLLocationCoordinate2D(latitude: 37.718242366859215, longitude: -122.45717525482178)
            ],
            [
                CLLocationCoordinate2D(latitude: 31.728167146023935, longitude: 26.279296875),
                CLLocationCoordinate2D(latitude: 32.69486597787505, longitude: 21.796875),
                CLLocationCoordinate2D(latitude: 29.99300228455108, longitude: 18.80859375),
                CLLocationCoordinate2D(latitude: 33.137551192346145, longitude: 12.919921874999998),
                CLLocationCoordinate2D(latitude: 35.60371874069731, longitude: 10.1953125),
                CLLocationCoordinate2D(latitude: 36.527294814546245, longitude: 4.921875),
                CLLocationCoordinate2D(latitude: 36.527294814546245, longitude: -1.669921875),
                CLLocationCoordinate2D(latitude: 34.74161249883172, longitude: -5.44921875),
                CLLocationCoordinate2D(latitude: 32.99023555965106, longitude: -8.7890625)
            ],
            [
                CLLocationCoordinate2D(latitude: 51.52204224896724, longitude: -0.10919809341430663),
                CLLocationCoordinate2D(latitude: 51.521942114455435, longitude: -0.10923027992248535),
                CLLocationCoordinate2D(latitude: 51.52186200668747, longitude: -0.10916590690612793),
                CLLocationCoordinate2D(latitude: 51.52177522311313, longitude: -0.10904788970947266),
                CLLocationCoordinate2D(latitude: 51.521601655468345, longitude: -0.10886549949645996),
                CLLocationCoordinate2D(latitude: 51.52138135712038, longitude: -0.10874748229980469),
                CLLocationCoordinate2D(latitude: 51.5206870765674, longitude: -0.10855436325073242),
                CLLocationCoordinate2D(latitude: 51.52027984939518, longitude: -0.10843634605407713),
                CLLocationCoordinate2D(latitude: 51.519952729849024, longitude: -0.10839343070983887),
                CLLocationCoordinate2D(latitude: 51.51957887606202, longitude: -0.10817885398864746),
                CLLocationCoordinate2D(latitude: 51.51928513164789, longitude: -0.10814666748046874),
                CLLocationCoordinate2D(latitude: 51.518624199789016, longitude: -0.10789990425109863),
                CLLocationCoordinate2D(latitude: 51.51778299991493, longitude: -0.10759949684143065)
            ]
        ];
        for line in lines {
            for point in line {
                snapped = closestCoordinate(on: line, to: point)
                XCTAssertEqual(point, snapped?.coordinate, "point on joint should stay in place")
            }
        }
        
        // turf-point-on-line - points on top of line
        line = [
            CLLocationCoordinate2D(latitude: 51.52204224896724, longitude: -0.10919809341430663),
            CLLocationCoordinate2D(latitude: 51.521942114455435, longitude: -0.10923027992248535),
            CLLocationCoordinate2D(latitude: 51.52186200668747, longitude: -0.10916590690612793),
            CLLocationCoordinate2D(latitude: 51.52177522311313, longitude: -0.10904788970947266),
            CLLocationCoordinate2D(latitude: 51.521601655468345, longitude: -0.10886549949645996),
            CLLocationCoordinate2D(latitude: 51.52138135712038, longitude: -0.10874748229980469),
            CLLocationCoordinate2D(latitude: 51.5206870765674, longitude: -0.10855436325073242),
            CLLocationCoordinate2D(latitude: 51.52027984939518, longitude: -0.10843634605407713),
            CLLocationCoordinate2D(latitude: 51.519952729849024, longitude: -0.10839343070983887),
            CLLocationCoordinate2D(latitude: 51.51957887606202, longitude: -0.10817885398864746),
            CLLocationCoordinate2D(latitude: 51.51928513164789, longitude: -0.10814666748046874),
            CLLocationCoordinate2D(latitude: 51.518624199789016, longitude: -0.10789990425109863),
            CLLocationCoordinate2D(latitude: 51.51778299991493, longitude: -0.10759949684143065),
        ]
        let dist = distance(along: line)
        let increment = dist / metersPerMile / 10
        for i in 0..<10 {
            let point = coordinate(at: increment * Double(i) * metersPerMile, fromStartOf: line)
            XCTAssertNotNil(point)
            if let point = point {
                let snapped = closestCoordinate(on: line, to: point)
                XCTAssertNotNil(snapped)
                if let snapped = snapped {
                    let shift = point - snapped.coordinate
                    XCTAssertLessThan(shift / metersPerMile, 0.000001, "point should not shift far")
                }
            }
        }
        
        // turf-point-on-line - point along line
        line = [
            CLLocationCoordinate2D(latitude: 37.72003306385638, longitude: -122.45717525482178),
            CLLocationCoordinate2D(latitude: 37.718242366859215, longitude: -122.45717525482178),
        ]
        let pointAlong = coordinate(at: 0.019 * metersPerMile, fromStartOf: line)
        XCTAssertNotNil(pointAlong)
        if let point = pointAlong {
            let snapped = closestCoordinate(on: line, to: point)
            XCTAssertNotNil(snapped)
            if let snapped = snapped {
                let shift = point - snapped.coordinate
                XCTAssertLessThan(shift / metersPerMile, 0.00001, "point should not shift far")
            }
        }
        
        // turf-point-on-line - points on sides of lines
        line = [
            CLLocationCoordinate2D(latitude: 37.72125936929241, longitude: -122.45616137981413),
            CLLocationCoordinate2D(latitude: 37.718242366859215, longitude: -122.45717525482178),
        ]
        points = [
            CLLocationCoordinate2D(latitude: 37.71881098149625, longitude: -122.45702505111694),
            CLLocationCoordinate2D(latitude: 37.719235317933844, longitude: -122.45733618736267),
            CLLocationCoordinate2D(latitude: 37.72027068864082, longitude: -122.45686411857605),
            CLLocationCoordinate2D(latitude: 37.72063561093274, longitude: -122.45652079582213),
        ]
        for point in points {
            let snapped = closestCoordinate(on: line, to: point)
            XCTAssertNotNil(snapped)
            if let snapped = snapped {
                XCTAssertNotEqual(snapped.coordinate, points.first, "point should not snap to first vertex")
                XCTAssertNotEqual(snapped.coordinate, points.last, "point should not snap to last vertex")
            }
        }
    }
    
    func testCoordinateAlong() {
        // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-along/test.js
        
        let json = Fixture.JSONFromFileNamed(name: "dc-line")
        let line = ((json["geometry"] as! [String: Any])["coordinates"] as! [[Double]]).map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
        
        let pointsAlong = [
            coordinate(at: 1 * metersPerMile, fromStartOf: line),
            coordinate(at: 1.2 * metersPerMile, fromStartOf: line),
            coordinate(at: 1.4 * metersPerMile, fromStartOf: line),
            coordinate(at: 1.6 * metersPerMile, fromStartOf: line),
            coordinate(at: 1.8 * metersPerMile, fromStartOf: line),
            coordinate(at: 2 * metersPerMile, fromStartOf: line),
            coordinate(at: 100 * metersPerMile, fromStartOf: line),
            coordinate(at: 0, fromStartOf: line),
        ]
        for point in pointsAlong {
            XCTAssertNotNil(point)
        }
        XCTAssertEqual(pointsAlong.count, 8)
        XCTAssertEqual(pointsAlong.last!, line.first!)
    }
    
    func testDistance() {
        let point1 = CLLocationCoordinate2D(latitude: 39.984, longitude: -75.343)
        let point2 = CLLocationCoordinate2D(latitude: 39.123, longitude: -75.534)
        let line = [point1, point2]
        
        // https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-distance/test.js
        let a = distance(along: line)
        XCTAssertEqualWithAccuracy(a, 97_159.57803131901, accuracy: 1)
    }
    
    func testPolylineAlong() {
        // https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-line-slice/test.js
        
        // turf-line-slice -- line1
        let line1 = [
            CLLocationCoordinate2D(latitude: 22.466878364528448, longitude: -97.88131713867188),
            CLLocationCoordinate2D(latitude: 22.175960091218524, longitude: -97.82089233398438),
            CLLocationCoordinate2D(latitude: 21.8704201873689, longitude: -97.6190185546875),
        ]
        var start = CLLocationCoordinate2D(latitude: 22.254624939561698, longitude: -97.79617309570312)
        var stop = CLLocationCoordinate2D(latitude: 22.057641623615734, longitude: -97.72750854492188)
        var sliced = polyline(along: line1, from: start, to: stop)
        let line1Out = [
            CLLocationCoordinate2D(latitude: 22.247393614241204, longitude: -97.83572934173804),
            CLLocationCoordinate2D(latitude: 22.175960091218524, longitude: -97.82089233398438),
            CLLocationCoordinate2D(latitude: 22.051208078134735, longitude: -97.7384672234217),
        ]
        XCTAssertEqualWithAccuracy(line1Out.first!.latitude, 22.247393614241204, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(line1Out.first!.longitude, -97.83572934173804, accuracy: 0.001)
        
        XCTAssertEqual(line1Out[1], line1[1])
        
        XCTAssertEqualWithAccuracy(line1Out.last!.latitude, 22.051208078134735, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(line1Out.last!.longitude, -97.7384672234217, accuracy: 0.001)
        XCTAssertEqual(sliced.count, 2)
        
        // turf-line-slice -- vertical
        let vertical = [
            CLLocationCoordinate2D(latitude: 38.70582415504791, longitude: -121.25447809696198),
            CLLocationCoordinate2D(latitude: 38.709767459877554, longitude: -121.25449419021606),
        ]
        start = CLLocationCoordinate2D(latitude: 38.70582415504791, longitude: -121.25447809696198)
        stop = CLLocationCoordinate2D(latitude: 38.70634324369764, longitude: -121.25447809696198)
        sliced = polyline(along: vertical, from: start, to: stop)
        XCTAssertEqual(sliced.count, 2, "no duplicated coords")
        XCTAssertNotEqual(sliced.first, sliced.last, "vertical slice should not collapse to first coordinate")
    }
    
    func testDistanceAlong() {
        let point1 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        let point2 = CLLocationCoordinate2D(latitude: 40, longitude: 40)
        let line = [point1, point2]
        
        let a = distance(along: line)
        XCTAssertEqualWithAccuracy(a, 2_928_304, accuracy: 1)
        
        
        // Adapted from: https://gist.github.com/bsudekum/2604b72ae42b6f88aa55398b2ff0dc22
        let b = distance(along: line, from: CLLocationCoordinate2D(latitude: 30, longitude: 30), to: CLLocationCoordinate2D(latitude: 40, longitude: 40))
        XCTAssertEqualWithAccuracy(b, 1_546_971, accuracy: 1)
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
