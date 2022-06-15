extension NavigationMapView: LocationAuthorization {
    
    func isAuthorized() -> Bool {
        return allowedAuthorizationStatuses.contains(authorizationStatus)
    }
}
