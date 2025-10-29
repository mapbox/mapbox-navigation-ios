import Foundation

/// Configuration for displaying roads congestion.
public struct CongestionConfiguration: Equatable, Sendable {
    /// Colors schema used.
    public var colors: CongestionColorsConfiguration
    /// Range configuration for congestion.
    public var ranges: CongestionRangesConfiguration
    /// Determines if the color transition between traffic congestion changes should use a soft gradient appearance
    /// or abrupt color change.
    public var displaySoftGradientForTraffic: Bool = true

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
