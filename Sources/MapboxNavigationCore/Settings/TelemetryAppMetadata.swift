import CoreLocation
import Foundation

/// Custom metadata that can be used with events in the telemetry pipeline.
public struct TelemetryAppMetadata: Equatable, Sendable {
    /// Name of the application.
    public let name: String
    /// Version of the application.
    public let version: String
    /// User ID relevant for the application context.
    public var userId: String?
    /// Session ID relevant for the application context.
    public var sessionId: String?

    /// nitializes a new `TelemetryAppMetadata` object.
    /// - Parameters:
    ///   - name: Name of the application.
    ///   - version: Version of the application.
    ///   - userId: User ID relevant for the application context.
    ///   - sessionId: Session ID relevant for the application context.
    public init(
        name: String,
        version: String,
        userId: String?,
        sessionId: String?
    ) {
        self.name = name
        self.version = version
        self.userId = userId
        self.sessionId = sessionId
    }
}

extension TelemetryAppMetadata {
    var configuration: [String: String?] {
        var dictionary: [String: String?] = [
            "name": name,
            "version": version,
        ]
        if let userId, !userId.isEmpty {
            dictionary["userId"] = userId
        }
        if let sessionId, !sessionId.isEmpty {
            dictionary["sessionId"] = sessionId
        }
        return dictionary
    }
}
