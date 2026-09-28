import MapboxCommon
import MapboxNavigationNative_Private

struct RouterClient: Sendable {
    var getRouteForDirectionsUri: @Sendable (
        _ directionsUri: String,
        _ options: GetRouteOptions,
        _ caller: GetRouteSignature,
        _ callbackDataRef: @escaping RouterDataRefCallback
    ) -> Cancelable

    var getRouteRefresh: @Sendable (_ options: RouteRefreshOptions, _ callback: @escaping RouterRefreshCallback)
        -> Cancelable

    var getRouteMapMatchedFor: @Sendable (
        _ matchingUri: String,
        _ options: GetRouteOptions,
        _ callbackDataRef: @escaping RouterDataRefCallback
    ) -> Cancelable

    var cancelAll: @Sendable () -> Void
}
