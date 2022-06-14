import CoreLocation

protocol LocationAuthorization {
    
    var authorizationStatus: CLAuthorizationStatus { get set }
    
    var accuracyAuthorization: CLAccuracyAuthorization { get set }
    
    var allowedAuthorizationStatuses: [CLAuthorizationStatus] { get set }
    
    func isAuthorized() -> Bool
}
