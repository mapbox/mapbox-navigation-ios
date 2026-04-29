import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// ADAS data for the specific ``RoadGraph/Edge``.
    public struct ADASAttributes: Sendable, Hashable {
        /// List of speed limits on the edge.
        /// Empty means no speed-limit data for the edge.
        /// Multiple values will have different conditions.
        public let speedLimit: [SpeedLimitInfo]
        /// List of slope values with their positions on the edge.
        ///
        /// `Double` value represents a slope in degrees.
        public let slopes: [ValueOnEdge<Double>]
        /// List of elevation values with their positions on the edge.
        ///
        /// `Double` value represents an elevation above the sea level in meters.
        public let elevations: [ValueOnEdge<Double>]
        /// List of curvature values with their positions on the edge.
        ///
        /// `Double` value represents the curvature in 1/m.
        public let curvatures: [ValueOnEdge<Double>]
        /// A flag indicating if the edge is a divided road.
        public let isDividedRoad: Bool?
        /// A flag indicating if the edge is a built up area.
        public let isBuiltUpArea: Bool?
        /// Describes the logical type of the road edge.
        ///
        /// Form Of Way information comes from ADAS tiles, may differ from the Valhalla value,
        /// but should be used for ADAS purposes.
        /// If not set, then the value is not known.
        public let formOfWay: FormOfWay?
        /// Road class in ETC2.0 format (Japan specific).
        public let etc2: ETC2RoadType
        /// List of ``RoadGraph/Edge/RoadItem``s, with their locations on the graph.
        public let roadItems: [ValueOnEdge<RoadItem>]

        init(_ native: MapboxNavigationNative_Private.EdgeAdasAttributes, edgeIdentifier: RoadGraph.Edge.Identifier) {
            self.speedLimit = native.speedLimit.map { SpeedLimitInfo($0) }
            self.slopes = native.slopes.map { ValueOnEdge($0, edgeIdentifier: edgeIdentifier) }
            self.elevations = native.elevations.map { ValueOnEdge($0, edgeIdentifier: edgeIdentifier) }
            self.curvatures = native.curvatures.map { ValueOnEdge($0, edgeIdentifier: edgeIdentifier) }
            self.isDividedRoad = native.isDividedRoad?.boolValue
            self.isBuiltUpArea = native.isBuiltUpArea?.boolValue
            self.formOfWay = native.formOfWay.map { FormOfWay($0.intValue) }
            self.etc2 = .init(native.etc2)
            self.roadItems = native.roadItems.map { ValueOnEdge($0, edgeIdentifier: edgeIdentifier) }
        }
    }
}
