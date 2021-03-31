import MapboxNavigationNative
import CoreLocation
import MapboxDirections

/**
 An object that notifies its delegate when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 Unlike `Router` classes such as `RouteController` and `LegacyRouteController`, this class operates without a predefined route, matching the user’s location to the road network at large. You can use a passive location manager to determine a starting point for a route that you calculate using the `Directions.calculate(_:completionHandler:)` method. If the user happens to be moving while you calculate the route, the passive location manager makes it less likely that the route will begin with a short segment on a side road or driveway and a confusing instruction to turn onto the current road.
 
 To find out when the user’s location changes, implement the `PassiveLocationDataSourceDelegate` protocol, or observe `Notification.Name.passiveLocationDataSourceDidUpdate` notifications for more detailed information.
 */
open class PassiveLocationDataSource: NSObject {
    /**
     Initializes the location data source with the given directions service.
     
     - parameter directions: The directions service that allows the location data source to access road network data. If this argument is omitted, the shared `Directions` object is used.
     - parameter systemLocationManager: The location manager that provides raw locations for the receiver to match against the road network.
     
     - postcondition: Call `startUpdatingLocation()` afterwards to begin receiving location updates.
     */
    public required init(directions: Directions = Directions.shared, systemLocationManager: NavigationLocationManager? = nil) {
        self.directions = directions
        Navigator.credentials = directions.credentials

        self.systemLocationManager = systemLocationManager ?? NavigationLocationManager()
        
        super.init()
        
        self.systemLocationManager.delegate = self
    }
    
    /**
     The directions service that allows the location data source to access road network data.
     */
    public let directions: Directions
    
    /**
     The location manager that provides raw locations for the receiver to match against the road network.
     */
    public let systemLocationManager: NavigationLocationManager
    
    /**
     The underlying navigator that performs map matching.
     */
    var navigator: MapboxNavigationNative.Navigator {
        return Navigator.shared.navigator
    }
    
    /**
     The location data source’s delegate.
     */
    public weak var delegate: PassiveLocationDataSourceDelegate?
    
    /**
     Starts the generation of location updates with an optional completion handler that gets called when the location data source is ready to receive snapped location updates.
     */
    public func startUpdatingLocation() {
        systemLocationManager.startUpdatingLocation()
    }

    /**
     A custom configuration for electronic horizon observations.
     
     Set this property to `nil` to use the default configuration.
     */
    public var electronicHorizonOptions: ElectronicHorizonOptions? {
        get {
            Navigator.shared.electronicHorizonOptions
        }
        set {
            Navigator.shared.electronicHorizonOptions = newValue
        }
    }
    
    /// The road graph that is updated as the passive location data source tracks the user’s location.
    public var roadGraph: RoadGraph {
        return Navigator.shared.roadGraph
    }
    
    /// The road objects store that is updated as the passive location data source tracks the user’s location.
    public var roadObjectsStore: RoadObjectsStore {
        return Navigator.shared.roadObjectsStore
    }
    
    /**
     Manually sets the current location.
     
     This method stops any automatic location updates.
     */
    public func updateLocation(_ location: CLLocation?) {
        guard let location = location else { return }
        systemLocationManager.stopUpdatingLocation()
        systemLocationManager.stopUpdatingHeading()
        self.didUpdate(locations: [location])
    }

    private func didUpdate(locations: [CLLocation]) {
        for location in locations {
            _ = try? navigator.updateLocation(for: FixLocation(location))
        }

        guard let lastRawLocation = locations.last else {
            return
        }

        let status = navigator.status(at: lastRawLocation.timestamp)
        let lastLocation = CLLocation(status.location)
        var speedLimit: Measurement<UnitSpeed>?
        var signStandard: SignStandard?

        delegate?.passiveLocationDataSource(self, didUpdateLocation: lastLocation, rawLocation: lastRawLocation)
        let matches = status.map_matcher_output.matches.map {
            Match(legs: [], shape: nil, distance: -1, expectedTravelTime: -1, confidence: $0.proba, weight: .routability(value: 1))
        }

        switch status.speedLimit?.localeSign {
        case .mutcd:
            signStandard  = .mutcd
        case .vienna:
            signStandard = .viennaConvention
        case .none:
            signStandard = nil
        }

        if let speed = status.speedLimit?.speedKmph as? Double {
            switch status.speedLimit?.localeUnit {
            case .milesPerHour:
                speedLimit = Measurement(value: speed, unit: .kilometersPerHour).converted(to: .milesPerHour)
            case .kilometresPerHour:
                speedLimit = Measurement(value: speed, unit: .kilometersPerHour)
            case .none:
                speedLimit = nil
            }
        }
        
        var userInfo: [NotificationUserInfoKey: Any] = [
            .locationKey: lastLocation,
            .rawLocationKey: lastRawLocation,
            .matchesKey: matches,
            .roadNameKey: status.roadName,
        ]
        if let speedLimit = speedLimit {
            userInfo[.speedLimitKey] = speedLimit
        }
        if let signStandard = signStandard {
            userInfo[.signStandardKey] = signStandard
        }
        NotificationCenter.default.post(name: .passiveLocationDataSourceDidUpdate, object: self, userInfo: userInfo)
    }
}

extension PassiveLocationDataSource: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdate(locations: locations)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.passiveLocationDataSource(self, didUpdateHeading: newHeading)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.passiveLocationDataSource(self, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #available(iOS 14.0, *) {
            delegate?.passiveLocationDataSourceDidChangeAuthorization(self)
        }
    }
}

/**
 A delegate of a `PassiveLocationDataSource` object implements methods that the location data source calls as the user’s location changes.
 */
public protocol PassiveLocationDataSourceDelegate: class {
    /// - seealso: `CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)`
    @available(iOS 14.0, *)
    func passiveLocationDataSourceDidChangeAuthorization(_ dataSource: PassiveLocationDataSource)
    
    /// - seealso: `CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)`
    func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateLocation location: CLLocation, rawLocation: CLLocation)
    
    /// - seealso: `CLLocationManagerDelegate.locationManager(_:didUpdateHeading:)`
    func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateHeading newHeading: CLHeading)
    
    /// - seealso: `CLLocationManagerDelegate.locationManager(_:didFailWithError:)`
    func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didFailWithError error: Error)
}

extension TileEndpointConfiguration {
    /**
     Initializes an object that configures a navigator to obtain routing tiles of the given version from an endpoint, using the given credentials.
              
           - parameter credentials: Credentials for accessing road network data.
           - parameter tilesVersion: Routing tile version.
           - parameter minimumDaysToPersistVersion: The minimum age in days that a tile version much reach before a new version can be requested from the tile endpoint.
     */
    convenience init(credentials: DirectionsCredentials, tilesVersion: String, minimumDaysToPersistVersion: Int?) {
        let host = credentials.host.absoluteString
        guard let accessToken = credentials.accessToken, !accessToken.isEmpty else {
            preconditionFailure("No access token specified in Info.plist")
        }
        let skuTokenProvider = SkuTokenProvider(with: credentials)
        
        self.init(host: host,
                  dataset: "mapbox/driving",
                  version: tilesVersion,
                  token: accessToken,
                  userAgent: URLSession.userAgent,
                  navigatorVersion: "",
                  skuTokenSource: skuTokenProvider,
                  minDiffInDaysToConsiderServerVersion: minimumDaysToPersistVersion as NSNumber?)
    }
}
