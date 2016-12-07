import CoreLocation
import MapboxDirections

typealias LocationRadians = Double
typealias RadianDistance = Double
typealias RadianDirection = Double

extension CLLocationDegrees {
    func toRadians() -> LocationRadians {
        return self * M_PI / 180.0
    }
    
    func toDegrees() -> CLLocationDirection {
        return self * 180.0 / M_PI
    }
}

let metersPerRadian = 6_373_000.0

struct RadianCoordinate2D {
    var latitude: LocationRadians
    var longitude: LocationRadians
    
    init(latitude: LocationRadians, longitude: LocationRadians) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(_ degreeCoordinate: CLLocationCoordinate2D) {
        latitude = degreeCoordinate.latitude.toRadians()
        longitude = degreeCoordinate.longitude.toRadians()
    }
    
    func direction(to coordinate: RadianCoordinate2D) -> RadianDirection {
        let a = sin(coordinate.longitude - longitude) * cos(coordinate.latitude)
        let b = cos(latitude) * sin(coordinate.latitude)
            - sin(latitude) * cos(coordinate.latitude) * cos(coordinate.longitude - longitude)
        return atan2(a, b)
    }
    
    func coordinate(at distance: RadianDistance, facing direction: RadianDirection) -> RadianCoordinate2D {
        let distance = distance, direction = direction
        let otherLatitude = asin(sin(latitude) * cos(distance)
            + cos(latitude) * sin(distance) * cos(direction))
        let otherLongitude = longitude + atan2(sin(direction) * sin(distance) * cos(latitude),
                                               cos(distance) - sin(latitude) * sin(otherLatitude))
        return RadianCoordinate2D(latitude: otherLatitude, longitude: otherLongitude)
    }
}

/// Returns the Haversine distance between two coordinates measured in radians.
func -(left: RadianCoordinate2D, right: RadianCoordinate2D) -> RadianDistance {
    let a = pow(sin((right.latitude - left.latitude) / 2), 2)
        + pow(sin((right.longitude - left.longitude) / 2), 2) * cos(left.latitude) * cos(right.latitude)
    return 2 * atan2(sqrt(a), sqrt(1 - a))
}

/// Returns the Haversine distance between two coordinates measured in degrees.
func -(left: CLLocationCoordinate2D, right: CLLocationCoordinate2D) -> CLLocationDistance {
    return (RadianCoordinate2D(left) - RadianCoordinate2D(right)) * metersPerRadian
}

extension CLLocationCoordinate2D {
    init(_ radianCoordinate: RadianCoordinate2D) {
        latitude = radianCoordinate.latitude.toDegrees()
        longitude = radianCoordinate.longitude.toDegrees()
    }
    
    /// Returns the direction from the receiver to the given coordinate.
    func direction(to coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        return RadianCoordinate2D(self).direction(to: RadianCoordinate2D(coordinate)).toDegrees()
    }
    
    /// Returns a coordinate a certain Haversine distance away in the given direction.
    func coordinate(at distance: CLLocationDistance, facing direction: CLLocationDirection) -> CLLocationCoordinate2D {
        let radianCoordinate = RadianCoordinate2D(self).coordinate(at: distance / metersPerRadian, facing: direction.toRadians())
        return CLLocationCoordinate2D(radianCoordinate)
    }
}

typealias LineSegment = (CLLocationCoordinate2D, CLLocationCoordinate2D)

/// Returns the intersection of two line segments.
func intersection(_ line1: LineSegment, _ line2: LineSegment) -> CLLocationCoordinate2D? {
    // Ported from https://github.com/Turfjs/turf-point-on-line/blob/3807292c7882389829c2c5bac68fe6da662f2390/index.js, in turn adapted from http://jsfiddle.net/justin_c_rounds/Gd2S2/light/
    let denominator = ((line2.1.latitude - line2.0.latitude) * (line1.1.longitude - line1.0.longitude))
        - ((line2.1.longitude - line2.0.longitude) * (line1.1.latitude - line1.0.latitude))
    guard denominator != 0 else {
        return nil
    }
    
    let dStartY = line1.0.latitude - line2.0.latitude
    let dStartX = line1.0.longitude - line2.0.longitude
    let numerator1 = (line2.1.longitude - line2.0.longitude) * dStartY - (line2.1.latitude - line2.0.latitude) * dStartX
    let numerator2 = (line1.1.longitude - line1.0.longitude) * dStartY - (line1.1.latitude - line1.0.latitude) * dStartX
    let a = numerator1 / denominator
    let b = numerator2 / denominator
    
    /// Intersection when the lines are cast infinitely in both directions.
    let intersection = CLLocationCoordinate2D(latitude: line1.0.longitude + a * (line1.1.longitude - line1.0.longitude),
                                              longitude: line1.0.latitude + a * (line1.1.latitude - line1.0.latitude))
    
    /// True if line 1 is finite and line 2 is infinite.
    let intersectsWithLine1 = a > 0 && a < 1
    /// True if line 2 is finite and line 1 is infinite.
    let intersectsWithLine2 = b > 0 && b < 1
    return intersectsWithLine1 && intersectsWithLine2 ? intersection : nil
}

struct CoordinateAlongPolyline {
    let coordinate: Array<CLLocationCoordinate2D>.Element
    let index: Array<CLLocationCoordinate2D>.Index
    let distance: CLLocationDistance
}

/// Returns the geographic coordinate along the polyline that is closest to the given coordinate as the crow flies. The returned coordinate may not correspond to one of the polyline’s vertices, but it always lies along the polyline.
func closestCoordinate(on polyline: [CLLocationCoordinate2D], to coordinate: CLLocationCoordinate2D, includeDistanceToNextCoordinate: Bool = false) -> CoordinateAlongPolyline? {
    // Ported from https://github.com/Turfjs/turf-point-on-line/blob/3807292c7882389829c2c5bac68fe6da662f2390/index.js
    let polyline = polyline, coordinate = coordinate
    guard !polyline.isEmpty else {
        return nil
    }
    guard polyline.count > 1 else {
        return CoordinateAlongPolyline(coordinate: polyline.first!, index: 0, distance: coordinate - polyline.first!)
    }
    
    // Turf uses a thousand miles, but a thousand kilometers will do.
    let far: CLLocationDistance = 1_000_000
    var closestCoordinate: CoordinateAlongPolyline?
    
    for var index in 0..<polyline.count - 1 {
        let segment = (polyline[index], polyline[index + 1])
        let distances = (coordinate - segment.0, coordinate - segment.1)
        let direction = segment.0.direction(to: segment.1)
        
        let perpendicularPoint1 = coordinate.coordinate(at: far, facing: direction + 90)
        let perpendicularPoint2 = coordinate.coordinate(at: far, facing: direction - 90)
        let intersectionPoint = lineIntersects(line1StartX: perpendicularPoint1.latitude, line1StartY: perpendicularPoint1.longitude, line1EndX: perpendicularPoint2.latitude, line1EndY: perpendicularPoint2.longitude, line2StartX: segment.0.latitude, line2StartY: segment.0.longitude, line2EndX: segment.1.latitude, line2EndY: segment.1.longitude)
        var intersectionDistance: CLLocationDistance? = intersectionPoint != nil ? coordinate - intersectionPoint! : nil
        
        if distances.0 < closestCoordinate?.distance ?? CLLocationDistanceMax {
            closestCoordinate = CoordinateAlongPolyline(coordinate: segment.0, index: index, distance: distances.0)
        }
        if distances.1 < closestCoordinate?.distance ?? CLLocationDistanceMax {
            closestCoordinate = CoordinateAlongPolyline(coordinate: segment.1, index: index + 1, distance: distances.1)
        }
        if intersectionDistance != nil && intersectionDistance! < closestCoordinate?.distance ?? CLLocationDistanceMax {
            if includeDistanceToNextCoordinate {
                intersectionDistance! += intersectionPoint! - segment.1
                index += 1
            } else if distances.1 < distances.0 {
                index += 1
            }
            closestCoordinate = CoordinateAlongPolyline(coordinate: intersectionPoint!, index: index, distance: intersectionDistance!)
        }
    }
    
    return closestCoordinate
}

/// Returns a subset of the polyline between the given coordinates.
func polyline(along polyline: [CLLocationCoordinate2D], from start: CLLocationCoordinate2D? = nil, to end: CLLocationCoordinate2D? = nil) -> [CLLocationCoordinate2D] {
    guard !polyline.isEmpty else {
        return []
    }
    
    let startVertex = (start != nil ? closestCoordinate(on: polyline, to: start!, includeDistanceToNextCoordinate: true) : nil) ?? CoordinateAlongPolyline(coordinate: polyline.first!, index: 0, distance: 0)
    let endVertex = (end != nil ? closestCoordinate(on: polyline, to: end!, includeDistanceToNextCoordinate: true) : nil) ?? CoordinateAlongPolyline(coordinate: polyline.last!, index: polyline.indices.last!, distance: 0)
    return Array(polyline[startVertex.index...endVertex.index])
}

/// Returns the distance along a slice of a polyline with the given endpoints.
func distance(along polyline: [CLLocationCoordinate2D], from start: CLLocationCoordinate2D? = nil, to end: CLLocationCoordinate2D? = nil) -> CLLocationDistance {
    // Ported from https://github.com/Turfjs/turf-line-slice/blob/b3985348bf3ea1507107641ad59ec1533023285b/index.js
    guard !polyline.isEmpty else {
        return 0
    }
    
    let startVertex = start != nil ? closestCoordinate(on: polyline, to: start!, includeDistanceToNextCoordinate: true) : nil
    let endVertex = end != nil ? closestCoordinate(on: polyline, to: end!, includeDistanceToNextCoordinate: true) : nil
    var vertices = (startVertex ?? CoordinateAlongPolyline(coordinate: polyline.first!, index: 0, distance: 0),
                    endVertex ?? CoordinateAlongPolyline(coordinate: polyline.last!, index: polyline.indices.last!, distance: 0))
    
    var length: CLLocationDistance = vertices.0.distance + vertices.1.distance
    if vertices.0.index > vertices.1.index {
        vertices = (vertices.1, vertices.0)
    } else if vertices.0.index == vertices.1.index {
        return length
    }
    
    if vertices.0.index != vertices.1.index {
        for index in vertices.0.index..<vertices.1.index {
            length += polyline[index + 1] - polyline[index]
        }
    }
    return length
}

// turf-along
func polyline(along polyline: [CLLocationCoordinate2D], within distance: CLLocationDistance, of coordinate: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
    let startVertex = closestCoordinate(on: polyline, to: coordinate)
    guard startVertex != nil && distance != 0 else {
        return []
    }
    
    var vertices: [CLLocationCoordinate2D] = [startVertex!.coordinate]
    var cumulativeDistance: CLLocationDistance = 0
    let addVertex = { (vertex: CLLocationCoordinate2D) -> Bool in
        let lastVertex = vertices.last!
        let incrementalDistance = lastVertex - vertex
        if cumulativeDistance + incrementalDistance <= abs(distance) {
            vertices.append(vertex)
            cumulativeDistance += incrementalDistance
            return true
        } else {
            let remainingDistance = abs(distance) - cumulativeDistance
            let direction = lastVertex.direction(to: vertex)
            let endpoint = lastVertex.coordinate(at: remainingDistance, facing: direction)
            vertices.append(endpoint)
            cumulativeDistance += remainingDistance
            return false
        }
    }
    
    //    var candidateVertices = distance > 0 ? polyline.suffixFrom(startVertex!.index) : polyline.prefixThrough(startVertex!.index).reverse()
    if distance > 0 {
        for vertex in polyline.suffix(from: startVertex!.index) {
            if !addVertex(vertex) {
                break
            }
        }
    } else {
        for vertex in polyline.prefix(through: startVertex!.index).reversed() {
            if !addVertex(vertex) {
                break
            }
        }
    }
    assert(round(cumulativeDistance) <= round(abs(distance)))
    return vertices
}

public func wrap(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    let d = maxValue - minValue
    return fmod((fmod((value - minValue), d) + d), d) + minValue
}

extension CLLocation {
    /// Returns a Boolean value indicating whether the receiver is within a given distance of a route step, inclusive.
    func isWithin(_ maximumDistance: CLLocationDistance, of routeStep: RouteStep) -> Bool {
        guard let closestCoordinate = closestCoordinate(on: routeStep.coordinates!, to: coordinate) else {
            return true
        }
        return closestCoordinate.distance < maximumDistance
    }
}

func lineIntersects(line1StartX: Double, line1StartY: Double, line1EndX: Double, line1EndY: Double, line2StartX: Double, line2StartY: Double, line2EndX: Double, line2EndY: Double) -> CLLocationCoordinate2D? {
    var result = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var onLine1 = false
    var onLine2 = false

    let denominator = ((line2EndY - line2StartY) * (line1EndX - line1StartX)) - ((line2EndX - line2StartX) * (line1EndY - line1StartY))
    
    if (denominator == 0) {
        return nil;
    }
    
    var a = line1StartY - line2StartY;
    var b = line1StartX - line2StartX;
    let numerator1 = ((line2EndX - line2StartX) * a) - ((line2EndY - line2StartY) * b);
    let numerator2 = ((line1EndX - line1StartX) * a) - ((line1EndY - line1StartY) * b);
    a = numerator1 / denominator;
    b = numerator2 / denominator;
    
    // if we cast these lines infinitely in both directions, they intersect here:
    result.latitude = line1StartX + (a * (line1EndX - line1StartX));
    result.longitude = line1StartY + (a * (line1EndY - line1StartY));
    
    // if line1 is a segment and line2 is infinite, they intersect if:
    if (a > 0 && a < 1) {
        onLine1 = true;
    }
    // if line2 is a segment and line1 is infinite, they intersect if:
    if (b > 0 && b < 1) {
        onLine2 = true;
    }
    // if line1 and line2 are segments, they intersect if both of the above are true
    if (onLine1 && onLine2) {
        return result;
    } else {
        return nil;
    }
}
