import CoreLocation
import Foundation

extension NavigationHistoryEvents {
    public struct Coordinate: Encodable, Sendable {
        var latitude: Double
        var longitude: Double

        public init(_ coordinate: CLLocationCoordinate2D) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }
    }

    public struct RoutablePoint: Encodable, Sendable {
        public var coordinates: Coordinate

        public init(coordinates: Coordinate) {
            self.coordinates = coordinates
        }
    }

    public struct SearchResultUsed: Event, Sendable {
        public enum Provider: String, Encodable, Sendable {
            case mapbox
        }

        public struct Payload: Encodable, Sendable {
            public var provider: Provider
            public var id: String

            public var name: String
            public var address: String
            public var coordinate: Coordinate

            public var routablePoint: [RoutablePoint]?

            public init(
                provider: Provider,
                id: String,
                name: String,
                address: String,
                coordinate: Coordinate,
                routablePoint: [RoutablePoint]?
            ) {
                self.provider = provider
                self.id = id
                self.name = name
                self.address = address
                self.coordinate = coordinate
                self.routablePoint = routablePoint
            }
        }

        public let eventType = "search_result_used"
        public var payload: Payload

        public init(payload: Payload) {
            self.payload = payload
        }
    }
}
