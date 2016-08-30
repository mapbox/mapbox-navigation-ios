import CoreLocation

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
    
    func directionToCoordinate(coordinate: RadianCoordinate2D) -> RadianDirection {
        let a = sin(coordinate.longitude - longitude) * cos(coordinate.latitude)
        let b = cos(latitude) * sin(coordinate.latitude)
            - sin(latitude) * cos(coordinate.latitude) * cos(coordinate.longitude - longitude)
        return atan2(a, b)
    }
    
    func coordinateAtDistance(distance: RadianDistance, direction: RadianDirection) -> RadianCoordinate2D {
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
    func directionToCoordinate(coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        return RadianCoordinate2D(self).directionToCoordinate(RadianCoordinate2D(coordinate)).toDegrees()
    }
    
    /// Returns a coordinate a certain Haversine distance away in the given direction.
    func coordinateAtDistance(distance: CLLocationDistance, direction: CLLocationDirection) -> CLLocationCoordinate2D {
        let radianCoordinate = RadianCoordinate2D(self).coordinateAtDistance(distance / metersPerRadian, direction: direction.toRadians())
        return CLLocationCoordinate2D(radianCoordinate)
    }
}

typealias LineSegment = (CLLocationCoordinate2D, CLLocationCoordinate2D)

/// Returns the intersection of two line segments.
func intersection(line1: LineSegment, _ line2: LineSegment) -> CLLocationCoordinate2D? {
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

/// Returns the geographic coordinate along the polyline that is closest to the given coordinate as the crow flies. The returned coordinate may not correspond to one of the polyline’s vertices, but it always lies along the polyline.
func closestCoordinateOnPolyline(polyline: [CLLocationCoordinate2D], toCoordinate coordinate: CLLocationCoordinate2D, includeDistanceToNextCoordinate: Bool = false) -> CoordinateAlongPolyline? {
    // Ported from https://github.com/Turfjs/turf-point-on-line/blob/3807292c7882389829c2c5bac68fe6da662f2390/index.js
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
        let direction = segment.0.directionToCoordinate(segment.1)
        
        var perpendicularPoint = coordinate.coordinateAtDistance(far, direction: direction + 90)
        var intersectionPoint = intersection((coordinate, perpendicularPoint), segment)
        if intersectionPoint == nil {
            perpendicularPoint = coordinate.coordinateAtDistance(far, direction: direction - 90)
            intersectionPoint = intersection((coordinate, perpendicularPoint), segment)
        }
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
func polylineBetweenCoordinates(polyline: [CLLocationCoordinate2D], start: CLLocationCoordinate2D? = nil, end: CLLocationCoordinate2D? = nil) -> [CLLocationCoordinate2D] {
    guard !polyline.isEmpty else {
        return []
    }
    
    let startVertex = (start != nil ? closestCoordinateOnPolyline(polyline, toCoordinate: start!, includeDistanceToNextCoordinate: true) : nil) ?? CoordinateAlongPolyline(coordinate: polyline.first!, index: 0, distance: 0)
    let endVertex = (end != nil ? closestCoordinateOnPolyline(polyline, toCoordinate: end!, includeDistanceToNextCoordinate: true) : nil) ?? CoordinateAlongPolyline(coordinate: polyline.last!, index: polyline.indices.last!, distance: 0)
    return Array(polyline[startVertex.index...endVertex.index])
}

/// Returns the distance along a slice of a polyline with the given endpoints.
func distanceAlongPolyline(polyline: [CLLocationCoordinate2D], start: CLLocationCoordinate2D? = nil, end: CLLocationCoordinate2D? = nil) -> CLLocationDistance {
    // Ported from https://github.com/Turfjs/turf-line-slice/blob/b3985348bf3ea1507107641ad59ec1533023285b/index.js
    guard !polyline.isEmpty else {
        return 0
    }
    
    let startVertex = start != nil ? closestCoordinateOnPolyline(polyline, toCoordinate: start!, includeDistanceToNextCoordinate: true) : nil
    let endVertex = end != nil ? closestCoordinateOnPolyline(polyline, toCoordinate: end!, includeDistanceToNextCoordinate: true) : nil
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
func polylineWithinDistance(polyline: [CLLocationCoordinate2D], location: CLLocationCoordinate2D, distance: CLLocationDistance) -> [CLLocationCoordinate2D] {
    let startVertex = closestCoordinateOnPolyline(polyline, toCoordinate: location)
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
            let direction = lastVertex.directionToCoordinate(vertex)
            let endpoint = lastVertex.coordinateAtDistance(remainingDistance, direction: direction)
            vertices.append(endpoint)
            cumulativeDistance += remainingDistance
            return false
        }
    }
    
//    var candidateVertices = distance > 0 ? polyline.suffixFrom(startVertex!.index) : polyline.prefixThrough(startVertex!.index).reverse()
    if distance > 0 {
        for vertex in polyline.suffixFrom(startVertex!.index) {
            if !addVertex(vertex) {
                break
            }
        }
    } else {
        for vertex in polyline.prefixThrough(startVertex!.index).reverse() {
            if !addVertex(vertex) {
                break
            }
        }
    }
    assert(round(cumulativeDistance) <= round(abs(distance)))
    return vertices
}
