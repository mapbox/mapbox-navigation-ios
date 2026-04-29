import Foundation
import MapboxDirections
import MapboxNavigationNative_Private

extension RoadGraph {
    /// Service Area, Parking Area indicator.
    public struct SapaType: Hashable, Equatable, Sendable {
        private let rawValue: Int
        private init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Type of area is unknown
        public static let none = SapaType(rawValue: 0)
        /// Service Area
        public static let serviceArea = SapaType(rawValue: 1)
        /// Parking/rest area
        public static let restArea = SapaType(rawValue: 2)
        /// Undefined value
        public static let undefined = SapaType(rawValue: -1)

        init(_ native: MapboxNavigationNative_Private.SapaType) {
            switch native {
            case .none:
                self = .none
            case .serviceArea:
                self = .serviceArea
            case .restArea:
                self = .restArea
            @unknown default:
                self = .undefined
            }
        }
    }
}
