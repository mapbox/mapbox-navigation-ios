import Foundation
import MapboxDirections
import MapboxNavigationNative_Private

extension RoadGraph {
    /// The surface type of road.
    /// See for details: https://wiki.openstreetmap.org/wiki/Key:surface
    public struct RoadSurface: Hashable, Equatable, Sendable {
        private let rawValue: Int
        private init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let pavedSmooth = RoadSurface(rawValue: 0)
        public static let paved = RoadSurface(rawValue: 1)
        public static let pavedRough = RoadSurface(rawValue: 2)
        public static let compacted = RoadSurface(rawValue: 3)
        public static let dirt = RoadSurface(rawValue: 4)
        public static let gravel = RoadSurface(rawValue: 5)
        public static let path = RoadSurface(rawValue: 6)
        public static let impassable = RoadSurface(rawValue: 7)
        public static let undefined = RoadSurface(rawValue: -1)

        init(_ native: MapboxNavigationNative_Private.RoadSurface) {
            switch native {
            case .pavedSmooth:
                self = .pavedSmooth
            case .paved:
                self = .paved
            case .pavedRough:
                self = .pavedRough
            case .dirt:
                self = .dirt
            case .gravel:
                self = .gravel
            case .path:
                self = .path
            case .impassable:
                self = .impassable
            case .compacted:
                self = .compacted
            @unknown default:
                self = .undefined
            }
        }
    }
}
