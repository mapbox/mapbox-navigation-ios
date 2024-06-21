import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Turf

/// A ``MapMatchingResponse`` object is a structure that corresponds to a map matching response returned by the Mapbox
/// Map Matching API.
public struct MapMatchingResponse: ForeignMemberContainer {
    public var foreignMembers: JSONObject = [:]

    /// The raw HTTP response from the Map Matching API.
    public let httpResponse: HTTPURLResponse?

    /// An array of ``Match`` objects.
    public var matches: [Match]?

    /// An array of ``Match/Tracepoint`` objects that represent the location an input point was matched with, in the
    /// order in which they were matched.
    /// This property will be `nil` if a trace point is omitted by the Map Matching API because it is an outlier.
    public var tracepoints: [Match.Tracepoint?]?

    /// The criteria for the map matching response.
    public let options: MatchOptions

    /// The credentials used to make the request.
    public let credentials: Credentials

    /// The time when this ``MapMatchingResponse`` object was created, which is immediately upon recieving the raw URL
    /// response.
    ///
    /// If you manually start fetching a task returned by `Directions.url(forCalculating:)`, this property is set to
    /// `nil`; use the `URLSessionTaskTransactionMetrics.responseEndDate` property instead. This property may also be
    /// set to `nil` if you create this result from a JSON object or encoded object.
    /// This property does not persist after encoding and decoding.
    public var created: Date = .init()
}

extension MapMatchingResponse: Codable {
    private enum CodingKeys: String, CodingKey {
        case matches = "matchings"
        case tracepoints
    }

    public init(
        httpResponse: HTTPURLResponse?,
        matches: [Match]? = nil,
        tracepoints: [Match.Tracepoint]? = nil,
        options: MatchOptions,
        credentials: Credentials
    ) {
        self.httpResponse = httpResponse
        self.matches = matches
        self.tracepoints = tracepoints
        self.options = options
        self.credentials = credentials
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.httpResponse = decoder.userInfo[.httpResponse] as? HTTPURLResponse

        guard let options = decoder.userInfo[.options] as? MatchOptions else {
            throw DirectionsCodingError.missingOptions
        }
        self.options = options

        guard let credentials = decoder.userInfo[.credentials] as? Credentials else {
            throw DirectionsCodingError.missingCredentials
        }
        self.credentials = credentials

        self.tracepoints = try container.decodeIfPresent([Match.Tracepoint?].self, forKey: .tracepoints)
        self.matches = try container.decodeIfPresent([Match].self, forKey: .matches)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(matches, forKey: .matches)
        try container.encodeIfPresent(tracepoints, forKey: .tracepoints)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }
}
