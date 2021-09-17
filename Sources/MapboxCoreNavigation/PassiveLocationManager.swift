// IMPORTANT: Tampering with any file that contains billing code is a violation of our ToS
// and will result in enforcement of the penalties stipulated in the ToS.

import MapboxNavigationNative
import CoreLocation
import MapboxDirections

/**
 An object that notifies its delegate when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 Unlike `Router` classes such as `RouteController` and `LegacyRouteController`, this class operates without a predefined route, matching the user’s location to the road network at large. You can use a passive location manager to determine a starting point for a route that you calculate using the `Directions.calculate(_:completionHandler:)` method. If the user happens to be moving while you calculate the route, the passive location manager makes it less likely that the route will begin with a short segment on a side road or driveway and a confusing instruction to turn onto the current road.
 
 To find out when the user’s location changes, implement the `PassiveLocationManagerDelegate` protocol, or observe `Notification.Name.passiveLocationManagerDidUpdate` notifications for more detailed information.

 - important: Creating an instance of this class will start a free-driving session. If the application goes into the background or you temporarily stop needing location updates for any other reason, temporarily pause the trip session using the `PassiveLocationManager.pauseTripSession()` method to avoid unnecessary costs. The trip session also stops when the instance is deinitialized. For more information, see the “[Pricing](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/)” guide.
 */
open class PassiveLocationManager: NSObject {
    private let sessionUUID: UUID = .init()

    /**
     Initializes the location manager with the given directions service.
     
     - parameter directions: The directions service that allows the location manager to access road network data. If this argument is omitted, the shared value of `NavigationSettings.directions` will be used.
     - parameter systemLocationManager: The system location manager that provides raw locations for the receiver to match against the road network.
     - parameter eventsManagerType: An optional events manager type to use.
     - parameter userInfo: An optional metadata to be provided as initial value of `NavigationEventsManager.userInfo` property.
     
     - postcondition: Call `startUpdatingLocation()` afterwards to begin receiving location updates.
     */
    public required init(directions: Directions = NavigationSettings.shared.directions,
                         systemLocationManager: NavigationLocationManager? = nil,
                         eventsManagerType: NavigationEventsManager.Type? = nil,
                         userInfo: [String: String?]? = nil) {
        self.directions = directions
        
        self.systemLocationManager = systemLocationManager ?? NavigationLocationManager()
        
        super.init()
        
        self.systemLocationManager.delegate = self

        let resolvedEventsManagerType = eventsManagerType ?? NavigationEventsManager.self
        let eventsManager = resolvedEventsManagerType.init(passiveNavigationDataSource: self,
                                                           accessToken: directions.credentials.accessToken)
        eventsManager.userInfo = userInfo
        _eventsManager = eventsManager

        subscribeNotifications()

        BillingHandler.shared.beginBillingSession(for: .freeDrive, uuid: sessionUUID)
    }
    
    deinit {
        BillingHandler.shared.stopBillingSession(with: sessionUUID)
        eventsManager.withBackupDataSource(active: nil, passive: self) {
            if self.lastRawLocation != nil {
                self.eventsManager.sendPassiveNavigationStop()
            }
        }
        unsubscribeNotifications()
    }

    private var _eventsManager: NavigationEventsManager?
    
    /**
     The directions service that allows the location manager to access road network data.
     */
    public let directions: Directions
    
    /**
     A `NavigationLocationManager` that provides raw locations for the receiver to match against the road network.
     */
    public let systemLocationManager: NavigationLocationManager

    /**
     The events manager, responsible for all telemetry.
     */
    public var eventsManager: NavigationEventsManager { _eventsManager! }
    
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
     A closure, which is called to report a result whether location update succeeded or not.
     
     - parameter result: Result, which in case of success contains location (which was updated),
     and error, in case of failure.
     */
    public typealias UpdateLocationCompletionHandler = (_ result: Result<CLLocation, Error>) -> Void
    
    /**
     Manually sets the current location.
     
     This method stops any automatic location updates.
     
     - parameter location: Location, which will be used by navigator.
     - parameter completion: Completion handler, which will be called when asynchronous operation completes.
     */
    public func updateLocation(_ location: CLLocation?, completion: UpdateLocationCompletionHandler? = nil) {
        guard let location = location else { return }
        systemLocationManager.stopUpdatingLocation()
        systemLocationManager.stopUpdatingHeading()
        
        didUpdate(locations: [location]) { result in
            completion?(result)
        }
    }

    private func didUpdate(locations: [CLLocation], completion: UpdateLocationCompletionHandler? = nil) {
        for location in locations {
            navigator.updateLocation(for: FixLocation(location)) { success in
                let result: Result<CLLocation, Error>
                if success {
                    result = .success(location)
                } else {
                    result = .failure(PassiveLocationManagerError.failedToChangeLocation)
                }
                
                completion?(result)
            }
        }

        let isFirstLocation = lastRawLocation == nil
        lastRawLocation = locations.last
        if isFirstLocation {
            eventsManager.sendPassiveNavigationStart()
        }
    }

    /**
     Pauses the Free Drive session.

     Use this method to extend the existing Free Drive session if you temporarily don't need navigation updates. For
     more info, read the [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
     */
    public func pauseTripSession() {
        BillingHandler.shared.pauseBillingSession(with: sessionUUID)
    }

    /**
     Resumes the Free Drive session.

     Resumes navigation updates paused by `PassiveLocationManager.pauseTripSession()`. For more info, read the
     [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
     */
    public func resumeTripSession() {
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
            signStandard = .mutcd
        case .vienna:
            signStandard = .viennaConvention
        case .none:
            signStandard = nil
        case .some(_):
            break
        }

        if let speed = status.speedLimit?.speedKmph as? Double {
            switch status.speedLimit?.localeUnit {
            case .milesPerHour:
                speedLimit = Measurement(value: speed, unit: .kilometersPerHour).converted(to: .milesPerHour)
            case .kilometresPerHour:
                speedLimit = Measurement(value: speed, unit: .kilometersPerHour)
            case .none:
                speedLimit = nil
            case .some(_):
                break
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

enum PassiveLocationManagerError: Error {
    case failedToChangeLocation
}
