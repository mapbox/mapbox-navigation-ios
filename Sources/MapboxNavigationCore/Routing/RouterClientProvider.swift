import MapboxNavigationNative_Private.MBNNRouterInterface_Internal

struct RouterClientProvider {
    var build: @Sendable (_ router: RouterInterface) -> RouterClient
}

extension RouterClientProvider {
    static var liveValue: RouterClientProvider {
        Self(
            build: { router in
                RouterClient(
                    getRouteForDirectionsUri: { directionsUri, options, caller, callbackDataRef in
                        router.getRouteForDirectionsUri(
                            directionsUri,
                            options: options,
                            caller: caller,
                            callbackDataRef: callbackDataRef
                        )
                    },
                    getRouteRefresh: { options, callback in
                        router.getRouteRefresh(for: options, callback: callback)
                    },
                    getRouteMapMatchedFor: { matchingUri, options, callbackDataRef in
                        router.getRouteMapMatchedFor(
                            matchingUri: matchingUri,
                            options: options,
                            callbackDataRef: callbackDataRef
                        )
                    },
                    cancelAll: {
                        router.cancelAll()
                    }
                )
            }
        )
    }
}
