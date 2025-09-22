import CoreLocation
import Foundation

/// Custom metadata that can be used with events in the telemetry pipeline.
public struct TelemetryAppMetadata: Equatable, Sendable {
    /// Name of the application.
    public let name: String
    /// Version of the application.
    public let version: String

    /// User ID relevant for the application context.
    @available(*, deprecated, message: "This property no longer has any effect.")
    public var userId: String?
    /// Session ID relevant for the application context.
    @available(*, deprecated, message: "This property no longer has any effect.")
    public var sessionId: String?

    /// Initializes a new ``TelemetryAppMetadata`` object.
    /// - Parameters:
    ///   - name: Name of the application.
    ///   - version: Version of the application.
    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }

    /// Initializes a new ``TelemetryAppMetadata`` object.
    /// - Parameters:
    ///   - name: Name of the application.
    ///   - version: Version of the application.
    ///   - userId: User ID relevant for the application context.
    ///   - sessionId: Session ID relevant for the application context.
    @available(*, deprecated, message: "Use 'init(name:version:)' instead.")
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
        [
            "name": name,
            "version": version,
        ]
    }
}
