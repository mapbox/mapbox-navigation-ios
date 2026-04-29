import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Turf

/// A Directions Refresh API response.
public struct RouteRefreshResponse: ForeignMemberContainer, Equatable {
    public var foreignMembers: JSONObject = [:]

    /// The raw HTTP response from the Directions Refresh API.
    public let httpResponse: HTTPURLResponse?

    /// The response identifier used to request the refreshed route.
    public let identifier: String

    /// The route index used to request the refreshed route.
    public var routeIndex: Int

    public var startLegIndex: Int

    /// A skeleton route that contains only the time-sensitive information that has been updated.
    public var route: RefreshedRoute

    /// The credentials used to make the request.
    public let credentials: Credentials

    /// The time when this ``RouteRefreshResponse`` object was created, which is immediately upon recieving the raw URL
    /// response.
    ///
    /// If you manually start fetching a task returned by
    /// `Directions.urlRequest(forRefreshing:routeIndex:currentLegIndex:)`, this property is set to `nil`; use the
    /// `URLSessionTaskTransactionMetrics.responseEndDate` property instead. This property may also be set to `nil` if
    /// you create this result from a JSON object or encoded object.
    ///
    /// This property does not persist after encoding and decoding.
    public var created = Date()
}

extension RouteRefreshResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier = "uuid"
        case route
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.httpResponse = decoder.userInfo[.httpResponse] as? HTTPURLResponse

        guard let credentials = decoder.userInfo[.credentials] as? Credentials else {
            throw DirectionsCodingError.missingCredentials
        }

        self.credentials = credentials

        if let identifier = decoder.userInfo[.responseIdentifier] as? String {
            self.identifier = identifier
        } else {
            throw DirectionsCodingError.missingOptions
        }

        self.route = try container.decode(RefreshedRoute.self, forKey: .route)

        if let routeIndex = decoder.userInfo[.routeIndex] as? Int {
            self.routeIndex = routeIndex
        } else {
            throw DirectionsCodingError.missingOptions
        }

        if let startLegIndex = decoder.userInfo[.startLegIndex] as? Int {
            self.startLegIndex = startLegIndex
        } else {
            throw DirectionsCodingError.missingOptions
        }

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(identifier, forKey: .identifier)

        try container.encode(route, forKey: .route)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }
}
