import Foundation
import CoreLocation
import MapboxNavigationNative

extension RoadObject {
    
    /**
     * Contains information about position of the point on the graph and
     * it's geo-position.
     *
     * note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
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
