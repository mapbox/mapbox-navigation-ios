import Foundation
import MapboxDirections

public typealias CongestionRange = Range<NumericCongestionLevel>

public extension CongestionRange {
    private(set) static var low: CongestionRange = CongestionRangeLow
    private(set) static var moderate: CongestionRange = CongestionRangeModerate
    private(set) static var heavy: CongestionRange = CongestionRangeHeavy
    private(set) static var severe: CongestionRange = CongestionRangeSevere

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
