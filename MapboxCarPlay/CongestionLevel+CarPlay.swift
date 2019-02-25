import Foundation
import MapboxDirections
import CarPlay

extension CongestionLevel {
    /**
     Converts a CongestionLevel to a CPTimeRemainingColor.
     */
    @available(iOS 12.0, *)
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
