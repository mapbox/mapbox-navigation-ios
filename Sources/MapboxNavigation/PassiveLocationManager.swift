import CoreLocation
import MapboxCoreNavigation

/**
 An object that notifies a map view when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 Unlike `Router` classes such as `RouteController` and `LegacyRouteController`, this class operates without a predefined route, matching the user’s location to the road network at large. If your application displays a `MapView` before starting turn-by-turn navigation, call `LocationManager.overrideLocationProvider(with:)` to override default location provider so that the map view always shows the location snapped to the road network. For example, use this class to show the user’s current location as they wander around town.
 
 This class depends on `PassiveLocationDataSource` to detect the user’s location as it changes. If you want location updates but do not need to display them on a map and do not want a dependency on the MapboxNavigation module, you can use `PassiveLocationDataSource` instead of this class.
 */
open class PassiveLocationManager: NavigationLocationProvider {
    /**
     Initializes the location manager with the given data source.
     
     - parameter dataSource: A data source that detects the user’s location as it changes.
     */
    public init(dataSource: PassiveLocationDataSource) {
        self.dataSource = dataSource
        
        super.init()
        dataSource.delegate = self
        self.locationManager = dataSource.systemLocationManager
    }
    
    /**
     The location manager’s data source, which detects the user’s location as it changes.
     */
    public let dataSource: PassiveLocationDataSource
    
    public override func startUpdatingLocation() {
        dataSource.startUpdatingLocation()
    }
    
}

extension PassiveLocationManager: PassiveLocationDataSourceDelegate {
    @available(iOS 14.0, *)
    public func passiveLocationDataSourceDidChangeAuthorization(_ dataSource: PassiveLocationDataSource) {
        delegate?.locationProviderDidChangeAuthorization(self)
    }
    
    public func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        delegate?.locationProvider(self, didUpdateLocations: [location])
    }
    
    public func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationProvider(self, didUpdateHeading: newHeading)
    }
    
    public func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didFailWithError error: Error) {
        delegate?.locationProvider(self, didFailWithError: error)
    }
}
