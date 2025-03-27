import MapboxNavigationNative_Private

struct RouterClient: Sendable {
    var getRouteForDirectionsUri: @Sendable (
        _ directionsUri: String,
        _ options: GetRouteOptions,
        _ caller: GetRouteSignature,
        _ callbackDataRef: @escaping RouterDataRefCallback
    ) -> UInt64

    var getRouteRefresh: @Sendable (_ options: RouteRefreshOptions, _ callback: @escaping RouterRefreshCallback)
        -> UInt64

    var getRouteMapMatchedFor: @Sendable (
        _ matchingUri: String,
        _ options: GetRouteOptions,
        _ callbackDataRef: @escaping RouterDataRefCallback
    ) -> UInt64

    var cancelRouteRequest: @Sendable (UInt64) -> Void

    var cancelRouteRefreshRequest: @Sendable (UInt64) -> Void

    var cancelRouteMapMatchedRequest: @Sendable (UInt64) -> Void

    var cancelAll: @Sendable () -> Void
}
