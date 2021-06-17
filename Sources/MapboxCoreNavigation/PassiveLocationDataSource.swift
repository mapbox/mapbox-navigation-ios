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
     - parameter tileStoreLocation: Configuration of `TileStore` location, where Navigation tiles are stored.
     
     - postcondition: Call `startUpdatingLocation()` afterwards to begin receiving location updates.
     */
    public required init(directions: Directions = Directions.shared, systemLocationManager: NavigationLocationManager? = nil, tileStoreLocation: TileStoreConfiguration.Location = .default) {
        self.directions = directions
        Navigator.credentials = directions.credentials
        Navigator.tilesURL = tileStoreLocation.tileStoreURL
        
        self.systemLocationManager = systemLocationManager ?? NavigationLocationManager()
        
        super.init()
        
        self.systemLocationManager.delegate = self

        subscribeNotifications()
    }
    
    deinit {
        unsubscribeNotifications()
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
     A `TileStore` instance used by navigator
     */
    open var navigatorTileStore: TileStore {
        return Navigator.shared.tileStore
    }
    
    /**
     The location data source’s delegate.
     */
    public weak var delegate: PassiveLocationDataSourceDelegate?
    
    /**
     Starts the generation of location updates. 
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
    
    /// The road object store that is updated as the passive location data source tracks the user’s location.
    public var roadObjectStore: RoadObjectStore {
        return Navigator.shared.roadObjectStore
    }

    /// The road object matcher that allows to match user-defined road objects.
    public var roadObjectMatcher: RoadObjectMatcher {
        return Navigator.shared.roadObjectMatcher
    }
    
    var lastRawLocation: CLLocation?
    
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
            navigator.updateLocation(for: FixLocation(location))
        }

        lastRawLocation = locations.last
    }
    
    @objc private func navigationStatusDidChange(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let status = userInfo[Navigator.NotificationUserInfoKey.statusKey] as? NavigationStatus else { return }
        DispatchQueue.main.async { [weak self] in
            self?.update(to: status)
        }
    }
    
    private func update(to status: NavigationStatus) {
        guard let lastRawLocation = lastRawLocation else { return }
        
        let lastLocation = CLLocation(status.location)
        var speedLimit: Measurement<UnitSpeed>?
        var signStandard: SignStandard?

        delegate?.passiveLocationDataSource(self, didUpdateLocation: lastLocation, rawLocation: lastRawLocation)
        let matches = status.mapMatcherOutput.matches.map {
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
    
    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationStatusDidChange),
                                               name: .navigationStatusDidChange,
                                               object: nil)
    }
    
    private func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     Path to the directory where history could be stored when `PassiveLocationDataSource.writeHistory(completionHandler:)` is called.
     */
    public static var historyDirectoryURL: URL? = nil {
        didSet {
            Navigator.historyDirectoryURL = historyDirectoryURL
        }
    }
    
    /**
     A closure to be called when history writing ends.
     
     - parameter historyFileURL: A path to file, where history was written to.
     */
    public typealias WriteHistoryCompletionHandler = (_ historyFileURL: URL?) -> Void
    
    /**
     Store history to the directory stored in `PassiveLocationDataSource.historyDirectoryURL` and asynchronously run a callback
     when writing finishes.
     
     - parameter completion: A block object to be executed when history writing ends.
     */
    public static func writeHistory(completionHandler: @escaping WriteHistoryCompletionHandler) {
        Navigator.shared.writeHistory(completionHandler: completionHandler)
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
public protocol PassiveLocationDataSourceDelegate: AnyObject {
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
           - parameter targetVersion: Routing tile version, which navigator would like to eventually switch to if it becomes available
     */
    convenience init(credentials: DirectionsCredentials, tilesVersion: String, minimumDaysToPersistVersion: Int?, targetVersion: String?) {
        let host = credentials.host.absoluteString
        guard let accessToken = credentials.accessToken, !accessToken.isEmpty else {
            preconditionFailure("No access token specified in Info.plist")
        }

        self.init(host: host,
                  dataset: "mapbox/driving",
                  version: tilesVersion,
                  token: accessToken,
                  userAgent: URLSession.userAgent,
                  navigatorVersion: "",
                  isFallback: targetVersion != nil,
                  versionBeforeFallback: targetVersion ?? tilesVersion,
                  minDiffInDaysToConsiderServerVersion: minimumDaysToPersistVersion as NSNumber?)
    }
}
