import Foundation

/// Configuration for displaying roads congestion.
public struct CongestionConfiguration: Equatable, Sendable {
    /// Colors schema used.
    public var colors: CongestionColorsConfiguration
    /// Range configuration for congestion.
    public var ranges: CongestionRangesConfiguration

    /// Default configuration.
    public static let `default` = CongestionConfiguration(
        colors: .default,
        ranges: .default
    )

    /// Creates a new ``CongestionConfiguration`` instance.
    /// - Parameters:
    ///   - colors: Colors schema used.
    ///   - ranges: Range configuration for congestion.
    public init(colors: CongestionColorsConfiguration, ranges: CongestionRangesConfiguration) {
        self.colors = colors
        self.ranges = ranges
    }
}
