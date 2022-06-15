import MapboxMaps

class SimulatedLocationProvider: LocationProvider {
    
    var locationProviderOptions: LocationOptions = LocationOptions()
    
    var authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
    
    var heading: CLHeading? = nil
    
    var headingOrientation: CLDeviceOrientation = .portrait
    
    var currentLocation: CLLocation
    
    weak var delegate: LocationProviderDelegate?
    
    init(currentLocation: CLLocation) {
        self.currentLocation = currentLocation
    }
    
    func setDelegate(_ delegate: LocationProviderDelegate) {
        self.delegate = delegate
    }
    
    func startUpdatingLocation() {
        delegate?.locationProvider(self, didUpdateLocations: [currentLocation])
    }
    
    func requestAlwaysAuthorization() {
        
    }
    
    func requestWhenInUseAuthorization() {
        
    }
    
    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        
    }
    
    func stopUpdatingLocation() {
        
    }
    
    func startUpdatingHeading() {
        
    }
    
    func stopUpdatingHeading() {
        
    }
    
    func dismissHeadingCalibrationDisplay() {
        
    }
}
