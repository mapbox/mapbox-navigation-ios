import MapboxNavigationNative

extension RouteIndices {
    public static func mock(
        routeId: String = "",
        legIndex: UInt32 = 0,
        step: UInt32 = 0,
        geometryIndex: UInt32 = 0,
        shapeIndex: UInt32 = 0,
        intersectionIndex: UInt32 = 0,
        isForkPointPassed: Bool = false
    ) -> Self {
        self.init(
            routeId: routeId,
            legIndex: legIndex,
            step: step,
            geometryIndex: geometryIndex,
            shapeIndex: shapeIndex,
            intersectionIndex: intersectionIndex,
            isForkPointPassed: isForkPointPassed
        )
    }
}
