// IMPORTANT: Tampering with any file that contains billing code is a violation of our ToS
// and will result in enforcement of the penalties stipulated in the ToS.

import MapboxNavigationNative
import CoreLocation
import MapboxCommon
import MapboxDirections

/**
 An object that notifies its delegate when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 Unlike `Router` classes such as `RouteController` and `LegacyRouteController`, this class operates without a predefined route, matching the user’s location to the road network at large. You can use a passive location manager to determine a starting point for a route that you calculate using the `Directions.calculate(_:completionHandler:)` method. If the user happens to be moving while you calculate the route, the passive location manager makes it less likely that the route will begin with a short segment on a side road or driveway and a confusing instruction to turn onto the current road.
 
 To find out when the user’s location changes, implement the `PassiveLocationManagerDelegate` protocol, or observe `Notification.Name.passiveLocationManagerDidUpdate` notifications for more detailed information.

 - important: Creating an instance of this class will start a free-driving session. If the application goes into the background or you temporarily stop needing location updates for any other reason, temporarily pause the trip session using the `PassiveLocationManager.pauseTripSession()` method to avoid unnecessary costs. The trip session also stops when the instance is deinitialized. For more information, see the “[Pricing](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/)” guide.
 */
open class PassiveLocationManager: NSObject {
    private let sessionUUID: UUID = .init()

    // MARK: Managing Location
    
    /**
     The directions service that allows the location manager to access road network data.
     */
    public let directions: Directions
    
    /**
     A `NavigationLocationManager` that provides raw locations for the receiver to match against the road network.
     */
    public let systemLocationManager: NavigationLocationManager

    /**
     The idealized user location. Snapped to the road network, if applicable, otherwise raw.
     - seeAlso: rawLocation
     */
    public var location: CLLocation? {
        return snappedLocation ?? rawLocation
    }
    
    /**
     The most recently received user location.
     - note: This is a raw location received from `systemLocationManager` or set manually via `updateLocation(_:completion:)`. To obtain an idealized location, use the `location` property.
     */
    public private(set) var rawLocation: CLLocation?
    
    /**
     The raw location, snapped to the road network.
     - important: If the rawLocation is outside of the route snapping tolerances, this value is nil.
     */
    var snappedLocation: CLLocation?
    
    /**
     The events manager, responsible for all telemetry.
     */
    public var eventsManager: NavigationEventsManager { _eventsManager! }
    
    private var _eventsManager: NavigationEventsManager?
    
    private let sharedNavigator = Navigator.shared
    
    /**
     The underlying navigator that performs map matching.
     */
    var navigator: MapboxNavigationNative.Navigator {
        return sharedNavigator.navigator
    }
    
    /**
     A `TileStore` instance used by navigator
     */
    open var navigatorTileStore: TileStore {
        return sharedNavigator.tileStore
    }
    
    /**
     The location manager's delegate.
     */
    public weak var delegate: PassiveLocationManagerDelegate?
    
    // MARK: Starting and Stopping the Location Manager
    
    /**
     Starts the generation of location updates. 
     */
    public func startUpdatingLocation() {
        systemLocationManager.startUpdatingLocation()
    }
    
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
        // NOTE: We should stop updating `navigator` with locations if billing session isn't running.
        //       To be replaced by `Navigator` pause/resume functionality once available.
        guard BillingHandler.shared.sessionState(uuid: sessionUUID) == .running else {
            completion?(.failure(PassiveLocationManagerError.sessionIsNotRunning)); return
        }
        
        for location in locations {
            sharedNavigator.updateLocation(location) { success in
                let result: Result<CLLocation, Error>
                if success {
                    result = .success(location)
                } else {
                    result = .failure(PassiveLocationManagerError.failedToChangeLocation)
                }
                
                completion?(result)
            }
        }

        let isFirstLocation = rawLocation == nil
        rawLocation = locations.last
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
    
    /**
     Starts electronic horizon updates.

     Pass `nil` to use the default configuration.
     Updates will be delivered in `Notification.Name.electronicHorizonDidUpdatePosition` notification.
     For more info, read the [Electronic Horizon Guide](https://docs.mapbox.com/ios/beta/navigation/guides/electronic-horizon/).

     - parameter options: Options which will be used to configure electronic horizon updates.

     - postcondition: To change electronic horizon options call this method again with new options.
     
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public func startUpdatingElectronicHorizon(with options: ElectronicHorizonOptions? = nil) {
        sharedNavigator.startUpdatingElectronicHorizon(with: options)
    }

    /**
     Stops electronic horizon updates.
     */
    public func stopUpdatingElectronicHorizon() {
        sharedNavigator.stopUpdatingElectronicHorizon()
    }

    @objc private func navigationStatusDidChange(_ notification: NSNotification) {
        assert(Thread.isMainThread)
        
        guard let userInfo = notification.userInfo,
              let status = userInfo[Navigator.NotificationUserInfoKey.statusKey] as? NavigationStatus,
              BillingHandler.shared.sessionState(uuid: sessionUUID) == .running else { return }
        update(to: status)
    }
    
    private func update(to status: NavigationStatus) {
        guard let rawLocation = rawLocation else { return }
        
        let lastLocation = CLLocation(status.location)
        var speedLimit: Measurement<UnitSpeed>?
        var signStandard: SignStandard?

        snappedLocation = lastLocation
        
        delegate?.passiveLocationManager(self, didUpdateLocation: lastLocation, rawLocation: rawLocation)
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
            .rawLocationKey: rawLocation,
            .matchesKey: matches,
            .roadNameKey: status.roadName,
            .routeShieldRepresentationKey: status.routeShieldRepresentation
        ]
        if let speedLimit = speedLimit {
            userInfo[.speedLimitKey] = speedLimit
        }
        if let signStandard = signStandard {
            userInfo[.signStandardKey] = signStandard
        }
        userInfo[.mapMatchingResultKey] = MapMatchingResult(status: status)
        
        NotificationCenter.default.post(name: .passiveLocationManagerDidUpdate, object: self, userInfo: userInfo)
    }
    
    /**
     Initializes the location manager with the given directions service.
     
     - parameter directions: The directions service that allows the location manager to access road network data. If this argument is omitted, the shared value of `NavigationSettings.directions` will be used.
     - parameter systemLocationManager: The system location manager that provides raw locations for the receiver to match against the road network.
     - parameter eventsManagerType: An optional events manager type to use.
     - parameter userInfo: An optional metadata to be provided as initial value of `NavigationEventsManager.userInfo` property.
     - parameter datasetProfileIdentifier: custom profile setting, used for selecting tiles type for navigation. If set to `nil` - will not modify current profile setting.
     
     - postcondition: Call `startUpdatingLocation()` afterwards to begin receiving location updates.
     */
    public required init(directions: Directions = NavigationSettings.shared.directions,
                         systemLocationManager: NavigationLocationManager? = nil,
                         eventsManagerType: NavigationEventsManager.Type? = nil,
                         userInfo: [String: String?]? = nil,
                         datasetProfileIdentifier: ProfileIdentifier? = nil) {
        if let datasetProfileIdentifier = datasetProfileIdentifier {
            Navigator.datasetProfileIdentifier = datasetProfileIdentifier
        }
        
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
            if self.rawLocation != nil {
                self.eventsManager.sendPassiveNavigationStop()
            }
        }
        unsubscribeNotifications()
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
    
    /// The road graph that is updated as the passive location manager tracks the user’s location.
    public var roadGraph: RoadGraph {
        return sharedNavigator.roadGraph
    }
    
    /// The road object store that is updated as the passive location manager tracks the user’s location.
    public var roadObjectStore: RoadObjectStore {
        return sharedNavigator.roadObjectStore
    }

    /// The road object matcher that allows to match user-defined road objects.
    public var roadObjectMatcher: RoadObjectMatcher {
        return sharedNavigator.roadObjectMatcher
    }
}

extension PassiveLocationManager: HistoryRecording { }

extension PassiveLocationManager: CLLocationManagerDelegate {
    
    // MARK: Handling LocationManager Output
    
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
           - parameter datasetProfileIdentifier: profile setting, used for selecting tiles type for navigation.
     */
    convenience init(credentials: Credentials, tilesVersion: String, minimumDaysToPersistVersion: Int?, targetVersion: String?, datasetProfileIdentifier: ProfileIdentifier) {
        let host = credentials.host.absoluteString
        guard let accessToken = credentials.accessToken, !accessToken.isEmpty else {
            preconditionFailure("No access token specified in Info.plist")
        }
        
        self.init(host: host,
                  dataset: datasetProfileIdentifier.rawValue,
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
    /// Location updates are not possible when session is paused.
    case sessionIsNotRunning
}
