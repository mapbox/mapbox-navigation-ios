import CoreLocation
import Foundation

extension NavigationHistoryEvents {
    public struct SearchResults: Event, Sendable {
        public struct SearchResult: Encodable, Sendable {
            public var id: String
            public var name: String
            public var address: String
            public var coordinate: Coordinate?
            public var routablePoint: [RoutablePoint]?

            public init(
                id: String,
                name: String,
                address: String,
                coordinate: NavigationHistoryEvents.Coordinate? = nil,
                routablePoint: [NavigationHistoryEvents.RoutablePoint]? = nil
            ) {
                self.id = id
                self.name = name
                self.address = address
                self.coordinate = coordinate
                self.routablePoint = routablePoint
            }
        }

        public struct Payload: Encodable, Sendable {
            public var provider: SearchResultUsed.Provider
            public var request: String
            public var response: String?
            public var error: String?
            public var searchQuery: String
            public var results: [SearchResult]?

            public init(
                provider: NavigationHistoryEvents.SearchResultUsed.Provider,
                request: String,
                response: String? = nil,
                error: String? = nil,
                searchQuery: String,
                results: [NavigationHistoryEvents.SearchResults.SearchResult]? = nil
            ) {
                self.provider = provider
                self.request = request
                self.response = response
                self.error = error
                self.searchQuery = searchQuery
                self.results = results
            }
        }

        public let eventType = "search_results"
        public var payload: Payload

        public init(payload: Payload) {
            self.payload = payload
        }
    }
}
