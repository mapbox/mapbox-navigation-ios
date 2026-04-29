import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An error that occurs when calculating directions.
public enum DirectionsError: LocalizedError {
    public init(code: String?, message: String?, response: URLResponse?, underlyingError error: Error?) {
        if let response = response as? HTTPURLResponse {
            switch (response.statusCode, code ?? "") {
            case (200, "NoRoute"):
                self = .unableToRoute
            case (200, "NoSegment"):
                self = .unableToLocate
            case (200, "NoMatch"):
                self = .noMatches
            case (422, "TooManyCoordinates"):
                self = .tooManyCoordinates
            case (404, "ProfileNotFound"):
                self = .profileNotFound
            case (413, _):
                self = .requestTooLarge
            case (422, "InvalidInput"):
                self = .invalidInput(message: message)
            case (429, _):
                self = .rateLimited(
                    rateLimitInterval: response.rateLimitInterval,
                    rateLimit: response.rateLimit,
                    resetTime: response.rateLimitResetTime
                )
            default:
                self = .unknown(response: response, underlying: error, code: code, message: message)
            }
        } else {
            self = .unknown(response: response, underlying: error, code: code, message: message)
        }
    }

    /// There is no network connection available to perform the network request.
    case network(_: URLError)

    /// The server returned an empty response.
    case noData

    /// The API received input that it didn't understand.
    case invalidInput(message: String?)

    /// The server returned a response that isn’t correctly formatted.
    case invalidResponse(_: URLResponse?)

    /// No route could be found between the specified locations.
    ///
    /// Make sure it is possible to travel between the locations with the mode of transportation implied by the
    /// profileIdentifier option. For example, it is impossible to travel by car from one continent to another without
    /// either a land bridge or a ferry connection.
    case unableToRoute

    /// The specified coordinates could not be matched to the road network.
    ///
    /// Try again making sure that your tracepoints lie in close proximity to a road or path.
    case noMatches

    /// The request specifies too many coordinates.
    ///
    /// Try again with fewer coordinates.
    case tooManyCoordinates

    /// A specified location could not be associated with a roadway or pathway.
    ///
    /// Make sure the locations are close enough to a roadway or pathway. Try setting the
    /// ``Waypoint/coordinateAccuracy`` property of all the waypoints to `nil`.
    case unableToLocate

    /// Unrecognized profile identifier.
    ///
    /// Make sure the ``DirectionsOptions/profileIdentifier`` option is set to one of the predefined values, such as
    /// ``ProfileIdentifier/automobile``.
    case profileNotFound

    /// The request is too large.
    ///
    /// Try specifying fewer waypoints or giving the waypoints shorter names.
    case requestTooLarge

    /// Too many requests have been made with the same access token within a certain period of time.
    ///
    /// Wait before retrying.
    case rateLimited(rateLimitInterval: TimeInterval?, rateLimit: UInt?, resetTime: Date?)

    /// Unknown error case. Look at associated values for more details.
    case unknown(response: URLResponse?, underlying: Error?, code: String?, message: String?)

    public var failureReason: String? {
        switch self {
        case .network:
            return "The client does not have a network connection to the server."
        case .noData:
            return "The server returned an empty response."
        case .invalidInput(let message):
            return message
        case .invalidResponse:
            return "The server returned a response that isn’t correctly formatted."
        case .unableToRoute:
            return "No route could be found between the specified locations."
        case .noMatches:
            return "The specified coordinates could not be matched to the road network."
        case .tooManyCoordinates:
            return "The request specifies too many coordinates."
        case .unableToLocate:
            return "A specified location could not be associated with a roadway or pathway."
        case .profileNotFound:
            return "Unrecognized profile identifier."
        case .requestTooLarge:
            return "The request is too large."
        case .rateLimited(rateLimitInterval: let interval, rateLimit: let limit, _):
            guard let interval, let limit else {
                return "Too many requests."
            }
#if os(Linux)
            let formattedInterval = "\(interval) seconds"
#else
            let intervalFormatter = DateComponentsFormatter()
            intervalFormatter.unitsStyle = .full
            let formattedInterval = intervalFormatter.string(from: interval) ?? "\(interval) seconds"
#endif
            let formattedCount = NumberFormatter.localizedString(from: NSNumber(value: limit), number: .decimal)
            return "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
        case .unknown(_, underlying: let error, _, let message):
            return message
                ?? (error as NSError?)?.userInfo[NSLocalizedFailureReasonErrorKey] as? String
                ?? HTTPURLResponse.localizedString(forStatusCode: (error as NSError?)?.code ?? -1)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .network(_), .noData, .invalidInput, .invalidResponse:
            return nil
        case .unableToRoute:
            return "Make sure it is possible to travel between the locations with the mode of transportation implied by the profileIdentifier option. For example, it is impossible to travel by car from one continent to another without either a land bridge or a ferry connection."
        case .noMatches:
            return "Try again making sure that your tracepoints lie in close proximity to a road or path."
        case .tooManyCoordinates:
            return "Try again with 100 coordinates or fewer."
        case .unableToLocate:
            return "Make sure the locations are close enough to a roadway or pathway. Try setting the coordinateAccuracy property of all the waypoints to nil."
        case .profileNotFound:
            return "Make sure the profileIdentifier option is set to one of the provided constants, such as ProfileIdentifier.automobile."
        case .requestTooLarge:
            return "Try specifying fewer waypoints or giving the waypoints shorter names."
        case .rateLimited(rateLimitInterval: _, rateLimit: _, resetTime: let rolloverTime):
            guard let rolloverTime else {
                return nil
            }
            let formattedDate: String = DateFormatter.localizedString(
                from: rolloverTime,
                dateStyle: .long,
                timeStyle: .long
            )
            return "Wait until \(formattedDate) before retrying."
        case .unknown(_, underlying: let error, _, _):
            return (error as NSError?)?.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String
        }
    }
}

extension DirectionsError: Equatable {
    public static func == (lhs: DirectionsError, rhs: DirectionsError) -> Bool {
        switch (lhs, rhs) {
        case (.noData, .noData),
             (.unableToRoute, .unableToRoute),
             (.noMatches, .noMatches),
             (.tooManyCoordinates, .tooManyCoordinates),
             (.unableToLocate, .unableToLocate),
             (.profileNotFound, .profileNotFound),
             (.requestTooLarge, .requestTooLarge):
            return true
        case (.network(let lhsError), .network(let rhsError)):
            return lhsError == rhsError
        case (.invalidResponse(let lhsResponse), .invalidResponse(let rhsResponse)):
            return lhsResponse == rhsResponse
        case (.invalidInput(let lhsMessage), .invalidInput(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (
            .rateLimited(let lhsRateLimitInterval, let lhsRateLimit, let lhsResetTime),
            .rateLimited(let rhsRateLimitInterval, let rhsRateLimit, let rhsResetTime)
        ):
            return lhsRateLimitInterval == rhsRateLimitInterval
                && lhsRateLimit == rhsRateLimit
                && lhsResetTime == rhsResetTime
        case (
            .unknown(let lhsResponse, let lhsUnderlying, let lhsCode, let lhsMessage),
            .unknown(let rhsResponse, let rhsUnderlying, let rhsCode, let rhsMessage)
        ):
            return lhsResponse == rhsResponse
                && type(of: lhsUnderlying) == type(of: rhsUnderlying)
                && lhsUnderlying?.localizedDescription == rhsUnderlying?.localizedDescription
                && lhsCode == rhsCode
                && lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// An error that occurs when encoding or decoding a type defined by the MapboxDirections framework.
public enum DirectionsCodingError: Error {
    /// Decoding this type requires the `Decoder.userInfo` dictionary to contain the ``Swift/CodingUserInfoKey/options``
    /// key.
    case missingOptions

    /// Decoding this type requires the `Decoder.userInfo` dictionary to contain the
    /// ``Swift/CodingUserInfoKey/credentials`` key.
    case missingCredentials
}
