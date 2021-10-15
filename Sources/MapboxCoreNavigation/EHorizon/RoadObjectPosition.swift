import Foundation
import CoreLocation
import MapboxNavigationNative

extension RoadObject {
    
    /**
     * Contains information about position of the point on the graph and
     * it's geo-position.
     */
    public struct Position {
        
        /** Position on the graph */
        public let position: RoadGraph.Position
        
        /** Geo-position of the object */
        public let coordinate: CLLocationCoordinate2D
        
        /**
         Initializes a new `RoadObject.Position` object with a given position on the graph and coordinate of the object.
         */
        public init(position: RoadGraph.Position, coordinate: CLLocationCoordinate2D) {
            self.position = position
            self.coordinate = coordinate
        }
        
        init(_ native: MapboxNavigationNative.Position) {
            position = RoadGraph.Position(native.position)
            coordinate = native.coordinate
        }
    }
}
