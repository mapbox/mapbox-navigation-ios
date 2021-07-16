import MapboxNavigationNative
import CoreLocation
import MapboxDirections

/**
 An object that notifies its delegate when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 Unlike `Router` classes such as `RouteController` and `LegacyRouteController`, this class operates without a predefined route, matching the user’s location to the road network at large. You can use a passive location manager to determine a starting point for a route that you calculate using the `Directions.calculate(_:completionHandler:)` method. If the user happens to be moving while you calculate the route, the passive location manager makes it less likely that the route will begin with a short segment on a side road or driveway and a confusing instruction to turn onto the current road.
 
 To find out when the user’s location changes, implement the `PassiveLocationManagerDelegate` protocol, or observe `Notification.Name.passiveLocationManagerDidUpdate` notifications for more detailed information.
 */
open class PassiveLocationManager: NSObject {
    private let sessionUUID: UUID = .init()

    /**
     Initializes the location manager with the given directions service.
     
     - parameter directions: The directions service that allows the location manager to access road network data. If this argument is omitted, the shared `Directions` object is used.
     - parameter systemLocationManager: The system location manager that provides raw locations for the receiver to match against the road network.
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
        
        BillingHandler.shared.beginBillingSession(for: .freeDrive, uuid: sessionUUID)
    }
    
    deinit {
        BillingHandler.shared.stopBillingSession(with: sessionUUID)
        
        unsubscribeNotifications()
    }

    /**
     The directions service that allows the location manager to access road network data.
     */
    public let directions: Directions
    
    /**
     A `NavigationLocationManager` that provides raw locations for the receiver to match against the road network.
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
     The location manager's delegate.
     */
    public weak var delegate: PassiveLocationManagerDelegate?
    
    /**
     Starts the generation of location updates. 
     */
    public func startUpdatingLocation() {
        systemLocationManager.startUpdatingLocation()
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

    /// Suspends the driving session.
    ///
    /// Use this method when you no longer need to receive updates of location status to preserve existing billing session.
    public func pauseDriveSession() {
        BillingHandler.shared.pauseBillingSession(with: sessionUUID)
    }

    /// Resumes the driving session.
    ///
    /// Resumes location updates and billing session.
    public func resumeDriveSession() {
        BillingHandler.shared.resumeBillingSession(with: sessionUUID)
    }    
    
    @objc private func navigationStatusDidChange(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let status = userInfo[Navigator.NotificationUserInfoKey.statusKey] as? NavigationStatus,
              BillingHandler.shared.sessionState(uuid: sessionUUID) == .running else { return }
        DispatchQueue.main.async { [weak self] in
            self?.update(to: status)
        }
    }
    
    private func update(to status: NavigationStatus) {
        guard let lastRawLocation = lastRawLocation else { return }
        
        let lastLocation = CLLocation(status.location)
        var speedLimit: Measurement<UnitSpeed>?
        var signStandard: SignStandard?

        delegate?.passiveLocationManager(self, didUpdateLocation: lastLocation, rawLocation: lastRawLocation)
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
        NotificationCenter.default.post(name: .passiveLocationManagerDidUpdate, object: self, userInfo: userInfo)
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
    
    // MARK: Accessing Relevant Routing Data
    
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
    
    /// The road graph that is updated as the passive location manager tracks the user’s location.
    public var roadGraph: RoadGraph {
        return Navigator.shared.roadGraph
    }
    
    /// The road object store that is updated as the passive location manager tracks the user’s location.
    public var roadObjectStore: RoadObjectStore {
        return Navigator.shared.roadObjectStore
    }

    /// The road object matcher that allows to match user-defined road objects.
    public var roadObjectMatcher: RoadObjectMatcher {
        return Navigator.shared.roadObjectMatcher
    }
    
    // MARK: Recording History to Diagnose Problems
    
    /**
     Path to the directory where history could be stored when `PassiveLocationManager.writeHistory(completionHandler:)` is called.
     */
    public static var historyDirectoryURL: URL? = nil {
        didSet {
            Navigator.historyDirectoryURL = historyDirectoryURL
        }
    }
    
    /**
     Starts recording history for debugging purposes.
     
     - postcondition: Use the `stopRecordingHistory(writingFileWith:)` method to stop recording history and write the recorded history to a file.
     */
    public static func startRecordingHistory() {
        Navigator.shared.startRecordingHistory()
    }
    
    /**
     A closure to be called when history writing ends.
     
     - parameter historyFileURL: A URL to the file that contains history data. This argument is `nil` if no history data has been written because history recording has not yet begun. Use the `startRecordingHistory()` method to begin recording before attempting to write a history file.
     */
    public typealias HistoryFileWritingCompletionHandler = (_ historyFileURL: URL?) -> Void
    
    /**
     Stops recording history, asynchronously writing any recorded history to a file.
     
     Upon completion, the completion handler is called with the URL to a file in the directory specified by `PassiveLocationManager.historyDirectoryURL`. The file contains details about the passive location manager’s activity that may be useful to include when reporting an issue to Mapbox.
     
     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     - postcondition: To write history incrementally without an interruption in history recording, use the `startRecordingHistory()` method immediately after this method. If you use the `startRecordingHistory()` method inside the completion handler of this method, history recording will be paused while the file is being prepared.
     
     - parameter completionHandler: A closure to be executed when the history file is ready.
     */
    public static func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler) {
        Navigator.shared.stopRecordingHistory(writingFileWith: completionHandler)
    }
}

extension PassiveLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdate(locations: locations)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.passiveLocationManager(self, didUpdateHeading: newHeading)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.passiveLocationManager(self, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #available(iOS 14.0, *) {
            delegate?.passiveLocationManagerDidChangeAuthorization(self)
        }
    }
}

/**
 A delegate of a `PassiveLocationManager` object implements methods that the location manager calls as the user’s location changes.
 */
public protocol PassiveLocationManagerDelegate: AnyObject {
    /// - seealso: `CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)`
    @available(iOS 14.0, *)
    func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager)
    
    /// - seealso: `CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)`
    func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation)
    
    /// - seealso: `CLLocationManagerDelegate.locationManager(_:didUpdateHeading:)`
    func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading)
    
    /// - seealso: `CLLocationManagerDelegate.locationManager(_:didFailWithError:)`
    func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error)
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
