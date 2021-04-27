import Foundation
import MapboxDirections
import CoreLocation
import Turf
import CoreGraphics

extension Array {
    /**
     Conditionally remove each element depending on the elements immediately preceding and following it.
     
     - parameter shouldBeRemoved: A closure that is called once for each element in reverse order from last to first. The closure accepts the following arguments: the preceding element in the (unreversed) array, the element itself, and the following element in the (unreversed) array.
     */
    mutating func removeSeparators(where shouldBeRemoved: (Element?, Element, Element?) throws -> Bool) rethrows {
        for (index, element) in enumerated().reversed() {
            let precedingElement = lazy.prefix(upTo: index).last
            let followingElement = lazy.suffix(from: self.index(after: index)).first
            if try shouldBeRemoved(precedingElement, element, followingElement) {
                remove(at: index)
            }
        }
    }
}

extension Array where Element: NSAttributedString {
    /**
     Returns a new attributed string by concatenating the elements of the array, adding the given separator between each element.
     */
    func joined(separator: NSAttributedString = .init()) -> NSAttributedString {
        guard let first = first else {
            return NSAttributedString()
        }
        
        let joinedAttributedString = NSMutableAttributedString(attributedString: first)
        for element in dropFirst() {
            joinedAttributedString.append(separator)
            joinedAttributedString.append(element)
        }
        return joinedAttributedString
    }
}

extension Array where Iterator.Element == [CLLocationCoordinate2D]? {
    
    func flatten() -> [CLLocationCoordinate2D] {
        return self.map({ coords -> [CLLocationCoordinate2D] in
            if let coords = coords {
                return coords
            } else {
                return [kCLLocationCoordinate2DInvalid]
            }
        }).reduce([], +)
    }
}

extension Array where Iterator.Element == CLLocationCoordinate2D {

    /**
     Returns an array of congestion segments by associating the given congestion levels with the coordinates of the respective line segments that they apply to.
     
     This method coalesces consecutive line segments that have the same congestion level.
     
     For each item in the `CongestionSegment` collection a `CongestionLevel` substitution will take place that has a streets road class contained in the `roadClassesWithOverriddenCongestionLevels` collection.
     For each of these items the `CongestionLevel` for `.unknown` traffic congestion will be replaced with the `.low` traffic congestion.
     
     - parameter congestionLevels: The congestion levels along a leg. There should be one fewer congestion levels than coordinates.
     - parameter streetsRoadClasses: A collection of streets road classes for each geometry index in `Intersection`. There should be the same amount of `streetsRoadClasses` and `congestions`.
     - parameter roadClassesWithOverriddenCongestionLevels: Streets road classes for which a `CongestionLevel` substitution should occur.
     - returns: A list of `CongestionSegment` tuples with coordinate and congestion level.
     */
    func combined(_ congestionLevels: [CongestionLevel],
                  streetsRoadClasses: [MapboxStreetsRoadClass?]? = nil,
                  roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil) -> [CongestionSegment] {
        var segments: [CongestionSegment] = []
        segments.reserveCapacity(congestionLevels.count)
        
        var index = 0
        for (firstSegment, congestionLevel) in zip(zip(self, self.suffix(from: 1)), congestionLevels) {
            let coordinates = [firstSegment.0, firstSegment.1]
            
            var overriddenCongestionLevel = congestionLevel
            if let streetsRoadClasses = streetsRoadClasses,
               let roadClassesWithOverriddenCongestionLevels = roadClassesWithOverriddenCongestionLevels,
               streetsRoadClasses.indices.contains(index),
               let streetsRoadClass = streetsRoadClasses[index],
               congestionLevel == .unknown,
               roadClassesWithOverriddenCongestionLevels.contains(streetsRoadClass) {
                overriddenCongestionLevel = .low
            }
            
            if segments.last?.1 == overriddenCongestionLevel {
                segments[segments.count - 1].0 += coordinates
            } else {
                segments.append((coordinates, overriddenCongestionLevel))
            }
            
            index += 1
        }
        
        return segments
    }
    
    func sliced(from: CLLocationCoordinate2D? = nil, to: CLLocationCoordinate2D? = nil) -> [CLLocationCoordinate2D] {
        return LineString(self).sliced(from: from, to: to)?.coordinates ?? []
    }
    
    func distance(from: CLLocationCoordinate2D? = nil, to: CLLocationCoordinate2D? = nil) -> CLLocationDistance? {
        return LineString(self).distance(from: from, to: to)
    }
    
    func trimmed(from: CLLocationCoordinate2D? = nil, distance: CLLocationDistance) -> [CLLocationCoordinate2D] {
        if let fromCoord = from ?? self.first {
            return LineString(self).trimmed(from: fromCoord, distance: distance)?.coordinates ?? []
        } else {
            return []
        }
    }
    
    var centerCoordinate: CLLocationCoordinate2D {
        let avgLat = self.map({ $0.latitude }).reduce(0.0, +) / Double(self.count)
        let avgLng = self.map({ $0.longitude }).reduce(0.0, +) / Double(self.count)
        
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng)
    }
}

extension Array where Iterator.Element == CGPoint {
    
    var boundingBoxPoints: [CGPoint] {
        let yCoordinates = self.map({ $0.y })
        let xCoordinates = self.map({ $0.x })
        if let yMax = yCoordinates.max(),
           let xMin = xCoordinates.min(),
           let yMin = yCoordinates.min(),
           let xMax = xCoordinates.max() {
            let topLeftPoint = CGPoint(x: xMin, y: yMin)
            let topRightPoint = CGPoint(x: xMax, y: yMin)
            let bottomRightPoint = CGPoint(x: xMax, y: yMax)
            let bottomLeftPoint = CGPoint(x: xMin, y: yMax)
            
            return [topLeftPoint, topRightPoint, bottomRightPoint, bottomLeftPoint]
        }
        
        return []
    }
}
