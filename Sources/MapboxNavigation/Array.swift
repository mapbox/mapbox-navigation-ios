import Foundation
import MapboxDirections
import CoreLocation
import Turf
import CoreGraphics
import MapboxDirections

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
                segments[segments.count - 1].0 += [firstSegment.1]
            } else {
                segments.append((coordinates, overriddenCongestionLevel))
            }
            
            index += 1
        }
        
        return segments
    }
    
    /**
     Returns an array of road segments by associating road classes of corresponding line segments.
     
     Adjacent segments with the same `combiningRoadClasses` will be merged together.
     
     - parameter roadClasses: An array of `RoadClasses`along given segment. There should be one fewer congestion levels than coordinates.
     - parameter combiningRoadClasses: `RoadClasses` which will be joined if they are neighbouring each other.
     - returns: A list of `RoadClassesSegment` tuples with coordinate and road class.
     */
    func combined(_ roadClasses: [RoadClasses?],
                  combiningRoadClasses: RoadClasses? = nil) -> [RoadClassesSegment] {
        var segments: [RoadClassesSegment] = []
        segments.reserveCapacity(roadClasses.count)
        
        var index = 0
        for (firstSegment, currentRoadClass) in zip(zip(self, self.suffix(from: 1)), roadClasses) {
            let coordinates = [firstSegment.0, firstSegment.1]
            var definedRoadClass = currentRoadClass ?? RoadClasses()
            definedRoadClass = combiningRoadClasses?.intersection(definedRoadClass) ?? definedRoadClass
            
            if segments.last?.1 == definedRoadClass {
                segments[segments.count - 1].0 += [firstSegment.1]
            } else {
                segments.append((coordinates, definedRoadClass))
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

extension Array where Element == RouteStep {
    // Find the longest contiguous series of RouteSteps connected to the first one.
    //
    // tolerance: -- Maximum distance between the end of one RouteStep and the start of the next to still consider them connected. Defaults to 100 meters
    func continuousShape(tolerance: CLLocationDistance = 100) -> LineString? {
        guard count > 0 else { return nil }
        guard count > 1 else { return self[0].shape }

        let stepShapes = compactMap { $0.shape }
        let filteredStepShapes = zip(stepShapes, stepShapes.suffix(from: 1)).filter({
            guard let maneuverLocation = $1.coordinates.first else { return false }
            
            return $0.coordinates.last?.distance(to: maneuverLocation) ?? Double.greatestFiniteMagnitude < tolerance
        })

        let coordinates = filteredStepShapes.flatMap { (firstLine, secondLine) -> [CLLocationCoordinate2D] in
            return firstLine.coordinates
        }

        return LineString(coordinates)
    }
}
