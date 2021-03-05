import MapboxDirections
import Turf

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
