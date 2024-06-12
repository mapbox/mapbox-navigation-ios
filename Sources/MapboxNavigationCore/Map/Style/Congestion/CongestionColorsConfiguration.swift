import UIKit

/// Configuration settings for congestion colors for the main and alternative routes.
public struct CongestionColorsConfiguration: Equatable, Sendable {
    /// Color schema for the main route.
    public var mainRouteColors: Colors
    /// Color schema for the alternative route.
    public var alternativeRouteColors: Colors

    /// Default colors configuration.
    public static let `default` = CongestionColorsConfiguration(
        mainRouteColors: .defaultMainRouteColors,
        alternativeRouteColors: .defaultAlternativeRouteColors
    )

    /// Creates a new ``CongestionColorsConfiguration`` instance.
    /// - Parameters:
    ///   - mainRouteColors: Color schema for the main route.
    ///   - alternativeRouteColors: Color schema for the alternative route.
    public init(
        mainRouteColors: CongestionColorsConfiguration.Colors,
        alternativeRouteColors: CongestionColorsConfiguration.Colors
    ) {
        self.mainRouteColors = mainRouteColors
        self.alternativeRouteColors = alternativeRouteColors
    }
}

extension CongestionColorsConfiguration {
    /// Set of colors for different congestion levels.
    public struct Colors: Equatable, Sendable {
        /// Assigned color for `low` traffic.
        public var low: UIColor
        /// Assigned color for `moderate` traffic.
        public var moderate: UIColor
        /// Assigned color for `heavy` traffic.
        public var heavy: UIColor
        /// Assigned color for `severe` traffic.
        public var severe: UIColor
        /// Assigned color for `unknown` traffic.
        public var unknown: UIColor

        /// Default color scheme for the main route.
        public static let defaultMainRouteColors = Colors(
            low: .trafficLow,
            moderate: .trafficModerate,
            heavy: .trafficHeavy,
            severe: .trafficSevere,
            unknown: .trafficUnknown
        )

        /// Default color scheme for the alternative route.
        public static let defaultAlternativeRouteColors = Colors(
            low: .alternativeTrafficLow,
            moderate: .alternativeTrafficModerate,
            heavy: .alternativeTrafficHeavy,
            severe: .alternativeTrafficSevere,
            unknown: .alternativeTrafficUnknown
        )

        /// Creates a new ``CongestionColorsConfiguration`` instance.
        /// - Parameters:
        ///   - low: Assigned color for `low` traffic.
        ///   - moderate: Assigned color for `moderate` traffic.
        ///   - heavy: Assigned color for `heavy` traffic.
        ///   - severe: Assigned color for `severe` traffic.
        ///   - unknown: Assigned color for `unknown` traffic.
        public init(low: UIColor, moderate: UIColor, heavy: UIColor, severe: UIColor, unknown: UIColor) {
            self.low = low
            self.moderate = moderate
            self.heavy = heavy
            self.severe = severe
            self.unknown = unknown
        }
    }
}
