import MapboxCoreNavigation

extension RouteProgress {
    /**
     Returns true if the current route is complete.
     */
    var routeIsComplete: Bool {
        return isFinalLeg && currentLegProgress.userHasArrivedAtWaypoint && currentLegProgress.distanceRemaining <= 0
    }
}
