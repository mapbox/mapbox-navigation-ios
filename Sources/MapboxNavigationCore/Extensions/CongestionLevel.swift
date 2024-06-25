import CarPlay
import Foundation
import MapboxDirections

/// Range of numeric values determining congestion level.
///
/// Congestion ranges work with `NumericCongestionLevel` values that can be requested by specifying
/// `AttributeOptions.numericCongestionLevel` in `DirectionOptions.attributes` when making Directions request.
public typealias CongestionRange = Range<NumericCongestionLevel>

/// Configuration for connecting numeric congestion values to range categories.
public struct CongestionRangesConfiguration: Equatable, Sendable {
    /// Numeric range for low congestion.
    public var low: CongestionRange
    /// Numeric range for moderate congestion.
    public var moderate: CongestionRange
    /// Numeric range for heavy congestion.
    public var heavy: CongestionRange
    /// Numeric range for severe congestion.
    public var severe: CongestionRange

    /// Creates a new ``CongestionRangesConfiguration`` instance.
    public init(low: CongestionRange, moderate: CongestionRange, heavy: CongestionRange, severe: CongestionRange) {
        precondition(low.lowerBound >= 0, "Congestion level ranges can't include negative values.")
        precondition(
            low.upperBound <= moderate.lowerBound,
            "Values from the moderate congestion level range can't intersect with or be lower than ones from the low congestion level range."
        )
        precondition(
            moderate.upperBound <= heavy.lowerBound,
            "Values from the heavy congestion level range can't intersect with or be lower than ones from the moderate congestion level range."
        )
        precondition(
            heavy.upperBound <= severe.lowerBound,
            "Values from the severe congestion level range can't intersect with or be lower than ones from the heavy congestion level range."
        )
        precondition(severe.upperBound <= 101, "Congestion level ranges can't include values greater than 100.")

        self.low = low
        self.moderate = moderate
        self.heavy = heavy
        self.severe = severe
    }

    /// Default congestion ranges configuration.
    public static var `default`: Self {
        .init(
            low: 0..<40,
            moderate: 40..<60,
            heavy: 60..<80,
            severe: 80..<101
        )
    }
}

extension CongestionLevel {
    init(numericValue: NumericCongestionLevel?, configuration: CongestionRangesConfiguration) {
        guard let numericValue else {
            self = .unknown
            return
        }

        switch numericValue {
        case configuration.low:
            self = .low
        case configuration.moderate:
            self = .moderate
        case configuration.heavy:
            self = .heavy
        case configuration.severe:
            self = .severe
        default:
            self = .unknown
        }
    }

    /// Converts a CongestionLevel to a CPTimeRemainingColor.
    public var asCPTimeRemainingColor: CPTimeRemainingColor {
        switch self {
        case .unknown:
            return .default
        case .low:
            return .green
        case .moderate:
            return .orange
        case .heavy:
            return .red
        case .severe:
            return .red
        }
    }
}

extension RouteLeg {
    /// An array containing the traffic congestion level along each road segment in the route leg geometry.
    ///
    /// The array is formed either by converting values of `segmentNumericCongestionLevels` to ``CongestionLevel`` type
    /// (see ``CongestionRange``) or by taking `segmentCongestionLevels`, depending whether
    /// `AttributeOptions.numericCongestionLevel` or `AttributeOptions.congestionLevel` was specified in
    /// `DirectionsOptions.attributes` during route request.
    ///
    /// If both are present, `segmentNumericCongestionLevels` is preferred.
    ///
    /// If none are present, returns `nil`.
    public func resolveCongestionLevels(using configuration: CongestionRangesConfiguration) -> [CongestionLevel]? {
        let congestionLevels: [CongestionLevel]? = if let numeric = segmentNumericCongestionLevels {
            numeric.map { numericValue in
                CongestionLevel(numericValue: numericValue, configuration: configuration)
            }
        } else if let levels = segmentCongestionLevels {
            levels
        } else {
            nil
        }

        return congestionLevels
    }
}
