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
    
    
    /*
     Returns direction given two coordinates.
    */
    func direction(to coordinate: RadianCoordinate2D) -> RadianDirection {
        let a = sin(coordinate.longitude - longitude) * cos(coordinate.latitude)
        let b = cos(latitude) * sin(coordinate.latitude)
            - sin(latitude) * cos(coordinate.latitude) * cos(coordinate.longitude - longitude)
        return atan2(a, b)
    }
    
    
    /*
     Returns coordinate at a given distance and direction away from coordinate.
    */
    func coordinate(at distance: RadianDistance, facing direction: RadianDirection) -> RadianCoordinate2D {
        let distance = distance, direction = direction
        let otherLatitude = asin(sin(latitude) * cos(distance)
            + cos(latitude) * sin(distance) * cos(direction))
        let otherLongitude = longitude + atan2(sin(direction) * sin(distance) * cos(latitude),
                                               cos(distance) - sin(latitude) * sin(otherLatitude))
        return RadianCoordinate2D(latitude: otherLatitude, longitude: otherLongitude)
    }
}


/*
 Returns the Haversine distance between two coordinates measured in radians.
 */
func -(left: RadianCoordinate2D, right: RadianCoordinate2D) -> RadianDistance {
    let a = pow(sin((right.latitude - left.latitude) / 2), 2)
        + pow(sin((right.longitude - left.longitude) / 2), 2) * cos(left.latitude) * cos(right.latitude)
    return 2 * atan2(sqrt(a), sqrt(1 - a))
}


/*
 Returns the Haversine distance between two coordinates measured in degrees.
 */
func -(left: CLLocationCoordinate2D, right: CLLocationCoordinate2D) -> CLLocationDistance {
    return (RadianCoordinate2D(left) - RadianCoordinate2D(right)) * metersPerRadian
}


extension CLLocationCoordinate2D {
    init(_ radianCoordinate: RadianCoordinate2D) {
        latitude = radianCoordinate.latitude.toDegrees()
        longitude = radianCoordinate.longitude.toDegrees()
    }
    
    /// Returns the direction from the receiver to the given coordinate.
    public func direction(to coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        return RadianCoordinate2D(self).direction(to: RadianCoordinate2D(coordinate)).toDegrees()
    }
    
    /// Returns a coordinate a certain Haversine distance away in the given direction.
    public func coordinate(at distance: CLLocationDistance, facing direction: CLLocationDirection) -> CLLocationCoordinate2D {
        let radianCoordinate = RadianCoordinate2D(self).coordinate(at: distance / metersPerRadian, facing: direction.toRadians())
        return CLLocationCoordinate2D(radianCoordinate)
    }
}


typealias LineSegment = (CLLocationCoordinate2D, CLLocationCoordinate2D)


/* 
 Returns the intersection of two line segments.
 */
func intersection(_ line1: LineSegment, _ line2: LineSegment) -> CLLocationCoordinate2D? {
    // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-point-on-line/index.js, in turn adapted from http://jsfiddle.net/justin_c_rounds/Gd2S2/light/
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
    let intersection = CLLocationCoordinate2D(latitude: line1.0.latitude + a * (line1.1.latitude - line1.0.latitude),
                                              longitude: line1.0.longitude + a * (line1.1.longitude - line1.0.longitude))
    
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


/*
 Returns the geographic coordinate along the polyline that is closest to the given coordinate as the crow flies.
 
 The returned coordinate may not correspond to one of the polyline’s vertices, but it always lies along the polyline.
*/
func closestCoordinate(on polyline: [CLLocationCoordinate2D], to coordinate: CLLocationCoordinate2D) -> CoordinateAlongPolyline? {
    // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-point-on-line/index.js
    let polyline = polyline, coordinate = coordinate
    guard !polyline.isEmpty else {
        return nil
    }
    guard polyline.count > 1 else {
        return CoordinateAlongPolyline(coordinate: polyline.first!, index: 0, distance: coordinate - polyline.first!)
    }
    
    var closestCoordinate: CoordinateAlongPolyline?
    
    for var index in 0..<polyline.count - 1 {
        let segment = (polyline[index], polyline[index + 1])
        let distances = (coordinate - segment.0, coordinate - segment.1)
        
        let maxDistance = max(distances.0, distances.1)
        let direction = segment.0.direction(to: segment.1)
        let perpendicularPoint1 = coordinate.coordinate(at: maxDistance, facing: direction + 90)
        let perpendicularPoint2 = coordinate.coordinate(at: maxDistance, facing: direction - 90)
        let intersectionPoint = intersection((perpendicularPoint1, perpendicularPoint2), segment)
        let intersectionDistance: CLLocationDistance? = intersectionPoint != nil ? coordinate - intersectionPoint! : nil
        
        if distances.0 < closestCoordinate?.distance ?? CLLocationDistanceMax {
            closestCoordinate = CoordinateAlongPolyline(coordinate: segment.0, index: index, distance: distances.0)
        }
        if distances.1 < closestCoordinate?.distance ?? CLLocationDistanceMax {
            index = index + 1
            closestCoordinate = CoordinateAlongPolyline(coordinate: segment.1, index: index, distance: distances.1)
        }
        if intersectionDistance != nil && intersectionDistance! < closestCoordinate?.distance ?? CLLocationDistanceMax {
            closestCoordinate = CoordinateAlongPolyline(coordinate: intersectionPoint!, index: index, distance: intersectionDistance!)
        }
    }
    
    return closestCoordinate
}


/*
 Returns a subset of the polyline between given coordinates.
 */
public func polyline(along polyline: [CLLocationCoordinate2D], from start: CLLocationCoordinate2D? = nil, to end: CLLocationCoordinate2D? = nil) -> [CLLocationCoordinate2D] {
    // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-line-slice/index.js
    guard !polyline.isEmpty else {
        return []
    }
    
    let startVertex = (start != nil ? closestCoordinate(on: polyline, to: start!) : nil) ?? CoordinateAlongPolyline(coordinate: polyline.first!, index: 0, distance: 0)
    let endVertex = (end != nil ? closestCoordinate(on: polyline, to: end!) : nil) ?? CoordinateAlongPolyline(coordinate: polyline.last!, index: polyline.indices.last!, distance: 0)
    let ends: (CoordinateAlongPolyline, CoordinateAlongPolyline)
    if startVertex.index <= endVertex.index {
        ends = (startVertex, endVertex)
    } else {
        ends = (endVertex, startVertex)
    }
    
    var coords = ends.0.index == ends.1.index ? [] : Array(polyline[ends.0.index + 1...ends.1.index])
    coords.insert(ends.0.coordinate, at: 0)
    coords.append(ends.1.coordinate)
    
    return coords
}


/*
 Returns the distance along a slice of a polyline with the given endpoints.
 */
func distance(along line: [CLLocationCoordinate2D], from start: CLLocationCoordinate2D? = nil, to end: CLLocationCoordinate2D? = nil) -> CLLocationDistance {
    // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-line-slice/index.js
    guard !line.isEmpty else {
        return 0
    }
    
    let sliced = polyline(along: line, from: start, to: end)
    
    // Zip together the starts and ends of each segment, then map those pairs of coordinates to the distances between them, then take the sum.
    let distance = zip(sliced.prefix(upTo: sliced.count - 1), sliced.suffix(from: 1)).map(-).reduce(0, +)
    
    return distance
}


/*
 Returns a coordinate along a polyline at a certain distance from the start of the polyline.
 */
func coordinate(at distance: CLLocationDistance, fromStartOf polyline: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
    // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-along/index.js
    var traveled: CLLocationDistance = 0
    for i in 0..<polyline.count {
        guard distance < traveled || i < polyline.count - 1 else {
            break
        }
        
        if traveled >= distance {
            let overshoot = distance - traveled
            if overshoot == 0 {
                return polyline[i]
            }
            
            let direction = polyline[i].direction(to: polyline[i - 1]) - 180
            return polyline[i].coordinate(at: overshoot, facing: direction)
        }
        
        traveled += polyline[i] - polyline[i + 1]
    }
    
    return polyline.last
}


/*
 Returns a coordinate along a polyline with x units away from a coordinate
 */
public func polyline(along polyline: [CLLocationCoordinate2D], within distance: CLLocationDistance, of coordinate: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
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


/*
 Returns a normalized number given min and max bounds.
 */
public func wrap(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    let d = maxValue - minValue
    return fmod((fmod((value - minValue), d) + d), d) + minValue
}


extension CLLocation {
    /*
     Returns a Boolean value indicating whether the receiver is within a given distance of a route step, inclusive.
    */
    func isWithin(_ maximumDistance: CLLocationDistance, of routeStep: RouteStep) -> Bool {
        guard let closestCoordinate = closestCoordinate(on: routeStep.coordinates!, to: coordinate) else {
            return true
        }
        return closestCoordinate.distance < maximumDistance
    }
}


/*
 Returns the smallest angle between two angles
 */
func differenceBetweenAngles(_ alpha: CLLocationDegrees, _ beta: CLLocationDegrees) -> CLLocationDegrees {
    let phi = abs(beta - alpha).truncatingRemainder(dividingBy: 360)
    return phi > 180 ? 360 - phi : phi
}
