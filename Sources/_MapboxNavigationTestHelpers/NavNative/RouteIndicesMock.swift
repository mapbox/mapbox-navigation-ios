import MapboxNavigationNative_Private

extension RouteIndices {
    public static func mock(
        routeId: RouteIdentifier = .mock(),
        legIndex: UInt32 = 0,
        step: UInt32 = 0,
        geometryIndex: UInt32 = 0,
        legShapeIndex: UInt32 = 0,
        intersectionIndex: UInt32 = 0,
        isForkPointPassed: Bool = false
    ) -> Self {
        self.init(
            routeId: routeId,
            legIndex: legIndex,
            step: step,
            geometryIndex: geometryIndex,
            legShapeIndex: legShapeIndex,
            intersectionIndex: intersectionIndex,
            isForkPointPassed: isForkPointPassed
        )
    }
}
