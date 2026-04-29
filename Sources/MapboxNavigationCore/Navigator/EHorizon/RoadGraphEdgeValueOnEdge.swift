import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// Representation of an arbitrary value positioned along the Edge.
    public struct ValueOnEdge<ValueType: Hashable & Sendable>: Hashable, Sendable {
        /// Position on the graph.
        public let position: RoadGraph.Position
        /// Position on edge represented as a shape index.
        ///
        /// Convenience coordinate representation of ``position`` but in alternative format.
        /// Integer part is an index of edge segment and fraction
        /// is a position on the segment: 0 - left point, 1 - right point,
        /// 0.5 - in the middle between the segment points.
        /// Ex.: 3.5 means the middle the the 3rd segment on the Edge shape, shape has more then 4 points
        public let edgeShapeIndex: Double
        /// The value, attached to the specified position along the Edge.
        public let value: ValueType
    }
}

extension RoadGraph.Edge.ValueOnEdge<Double> {
    init(
        _ native: MapboxNavigationNative_Private.ValueOnEdge,
        edgeIdentifier: RoadGraph.Edge.Identifier
    ) {
        self.init(
            position: .init(
                edgeIdentifier: edgeIdentifier,
                fractionFromStart: native.percentAlong
            ),
            edgeShapeIndex: Double(native.shapeIndex),
            value: native.value
        )
    }
}

extension RoadGraph.Edge.ValueOnEdge<RoadGraph.Edge.RoadItem> {
    init(
        _ native: MapboxNavigationNative_Private.RoadItemOnEdge,
        edgeIdentifier: RoadGraph.Edge.Identifier
    ) {
        self.init(
            position: .init(
                edgeIdentifier: edgeIdentifier,
                fractionFromStart: native.percentAlong
            ),
            edgeShapeIndex: Double(native.shapeIndex),
            value: .init(native.roadItem)
        )
    }
}
