import Foundation
import MapboxDirections

/**
 Range of numeric values determining congestion level.

 Congestion ranges work with `NumericCongestionLevel` values that can be requested by specifying
 `AttributeOptions.numericCongestionLevel` in `DirectionOptions.attributes` when making Directions request.
 */
public typealias CongestionRange = Range<NumericCongestionLevel>

public extension CongestionRange {

    /// The range for low congestion traffic. Default value is 0..39
    private(set) static var low: CongestionRange = CongestionRangeLow

    /// The range for moderate congestion traffic. Default value is 40..59
    private(set) static var moderate: CongestionRange = CongestionRangeModerate

    /// The range for heavy congestion traffic. Default value is 60..79
    private(set) static var heavy: CongestionRange = CongestionRangeHeavy

    /// The range for severe congestion traffic. Default value is 80..100
    private(set) static var severe: CongestionRange = CongestionRangeSevere

    /**
     Sets custom ranges of `NumericCongestionLevel` values to be aggregated into one of `CongestionLevel` cases.

     Ranges can't overlap and value-wise should come in the following order: low, moderate, heavy, severe.
     In the case of leaving gaps between intervals, values from the gaps will be matched to `CongestionLevel.unknown`.
     */
    static func setCongestionRanges(low: CongestionRange, moderate: CongestionRange, heavy: CongestionRange, severe: CongestionRange) {
        precondition(low.lowerBound >= 0, "Congestion level ranges can't include negative values.")
        precondition(low.upperBound <= moderate.lowerBound, "Values from the moderate congestion level range can't intersect with or be lower than ones from the low congestion level range.")
        precondition(moderate.upperBound <= heavy.lowerBound, "Values from the heavy congestion level range can't intersect with or be lower than ones from the moderate congestion level range.")
        precondition(heavy.upperBound <= severe.lowerBound, "Values from the severe congestion level range can't intersect with or be lower than ones from the heavy congestion level range.")
        precondition(severe.upperBound <= CongestionRangeSevere.upperBound, "Congestion level ranges can't include values greater than 100.")

        self.low = low
        self.moderate = moderate
        self.heavy = heavy
        self.severe = severe
    }

    /**
     Resets congestion ranges to their defaul values.
     */
    static func resetCongestionRangesToDefault() {
        setCongestionRanges(low: CongestionRangeLow, moderate: CongestionRangeModerate, heavy: CongestionRangeHeavy, severe: CongestionRangeSevere)
    }
}

extension CongestionLevel {
    init(numericValue: NumericCongestionLevel?) {
        guard let numericValue = numericValue else {
            self = .unknown
            return
        }

        switch numericValue {
        case CongestionRange.low:
            self = .low
        case CongestionRange.moderate:
            self = .moderate
        case CongestionRange.heavy:
            self = .heavy
        case CongestionRange.severe:
            self = .severe
        default:
            self = .unknown
        }
    }
}

extension RouteLeg {
    /**
     An array containing the traffic congestion level along each road segment in the route leg geometry.

     The array is formed either by converting values of `segmentNumericCongestionLevels` to `CongestionLevel` type (see `CongestionRange`)
     or by taking `segmentCongestionLevels`, depening whether `AttributeOptions.numericCongestionLevel` or `AttributeOptions.congestionLevel`
     was specified in `DirectionsOptions.attributes` during Directions request.

     If both are present, `segmentNumericCongestionLevels` is preferred.

     If none are present, returns `nil`.
     */
    public var resolvedCongestionLevels: [CongestionLevel]? {
        let congestionLevels: [CongestionLevel]?

        if let numeric = segmentNumericCongestionLevels {
            congestionLevels = numeric.map(CongestionLevel.init(numericValue:))
        } else if let levels = segmentCongestionLevels {
            congestionLevels = levels
        } else {
            congestionLevels = nil
        }

        return congestionLevels
    }
}
