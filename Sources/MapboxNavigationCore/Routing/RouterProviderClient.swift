import MapboxNavigationNative_Private.MBNNRouterInterface_Internal

struct RouterProviderClient {
    var build: @Sendable (_ router: RouterInterface) -> RouterClient
}

extension RouterProviderClient {
    static var liveValue: RouterProviderClient {
        Self(
            build: { router in
                RouterClient(
                    getRouteForDirectionsUri: { directionsUri, options, caller, callbackDataRef in
                        return router.getRouteForDirectionsUri(
                            directionsUri,
                            options: options,
                            caller: caller,
                            callbackDataRef: callbackDataRef
                        )
                    },
                    getRouteRefresh: { options, callback in
                        return router.getRouteRefresh(for: options, callback: callback)
                    },
                    getRouteMapMatchedFor: { matchingUri, options, callbackDataRef in
                        return router.getRouteMapMatchedFor(
                            matchingUri: matchingUri,
                            options: options,
                            callbackDataRef: callbackDataRef
                        )
                    },
                    cancelRouteRequest: { token in
                        router.cancelRouteRequest(forToken: token)
                    },
                    cancelRouteRefreshRequest: { token in
                        router.cancelRouteRefreshRequest(forToken: token)
                    },
                    cancelRouteMapMatchedRequest: { token in
                        router.cancelRouteMapMatchedRequest(forToken: token)
                    },
                    cancelAll: {
                        router.cancelAll()
                    }
                )
            }
        )
    }
}
