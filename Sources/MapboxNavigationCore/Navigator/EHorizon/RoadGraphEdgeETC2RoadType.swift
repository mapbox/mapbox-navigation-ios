import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// ETC2.0 road class type.
    ///
    /// Japan specific.
    public struct ETC2RoadType: Hashable, Equatable, Sendable {
        private let rawValue: Int
        private init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        /// :nodoc:
        public static let unknown = ETC2RoadType(0)
        /// :nodoc:
        public static let highway = ETC2RoadType(1)
        /// :nodoc:
        public static let cityHighway = ETC2RoadType(2)
        /// :nodoc:
        public static let normalRoad = ETC2RoadType(3)
        /// :nodoc:
        public static let other = ETC2RoadType(4)
        /// :nodoc:
        public static let undefined = ETC2RoadType(-1)

        init(_ native: MapboxNavigationNative_Private.ETC2RoadType) {
            switch native {
            case .unknown:
                self = .unknown
            case .highway:
                self = .highway
            case .cityHighway:
                self = .cityHighway
            case .normalRoad:
                self = .normalRoad
            case .other:
                self = .other
            @unknown default:
                self = .undefined
            }
        }
    }
}
