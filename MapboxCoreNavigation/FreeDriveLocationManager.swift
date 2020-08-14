import MapboxNavigationNative
import CoreLocation
import MapboxDirections
import MapboxAccounts

public protocol FreeDriveDebugInfoListener: AnyObject {
    func didGet(location: CLLocation, with matches: [MapMatch], for rawLocation: CLLocation)
}

open class FreeDriveLocationManager: NavigationLocationManager, CLLocationManagerDelegate {
    /**
     The directions service that allows the location manager to access road network data.
     */
    public let directions: Directions
    
    public weak var debugInfoListener: FreeDriveDebugInfoListener? {
        get {
            proxyDelegate?.debugDelegate
        }
        set {
            proxyDelegate?.debugDelegate = newValue
        }
    }

    private var proxyDelegate: ProxyDelegate?

    /**
     Initializes the location manager with the given directions service.
     
     - parameter directions: The directions service that allows the location manager to access road network data. If this argument is omitted, the shared `Directions` object is used.
     
     - postcondition: Call `startUpdatingLocation(completionHandler:)` afterwards to begin receiving location updates.
     */
    public required init(directions: Directions = Directions.shared) {
        self.directions = directions
        
        let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
        let navigator = Navigator(profile: settingsProfile, config: NavigatorConfig() , customConfig: "")
        
        let proxyDelegate = ProxyDelegate()
        proxyDelegate.navNative = navigator
        self.proxyDelegate = proxyDelegate
        
        super.init()

        super.delegate = proxyDelegate
    }
    
    public override func startUpdatingLocation() {
        startUpdatingLocation(completionHandler: nil)
    }
    
    /**
     Starts the generation of location updates with an optional completion handler that gets called when the location manager is ready to receive snapped location updates.
     */
    public func startUpdatingLocation(completionHandler: ((Error?) -> Void)?) {
        super.startUpdatingLocation()
        
        let tilesVersion = RouteTilesVersion(with: directions.credentials)
        tilesVersion.getAvailableVersions { availableVersions in
            if let latestVersion = availableVersions.last {
                tilesVersion.currentVersion = latestVersion
                do {
                    try self.configureNavigator(withTilesVersion: latestVersion)
                    completionHandler?(nil)
                } catch {
                    completionHandler?(error)
                }
            }
        }
    }
    
    func configureNavigator(withTilesVersion tilesVersion: String) throws {
        let endpointConfig = TileEndpointConfiguration(directions: directions, tilesVersion: tilesVersion)

        guard var tilesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            preconditionFailure("No Caches directory to create the tile directory inside")
        }
        tilesURL.appendPathComponent(tilesVersion, isDirectory: true)
        // Tiles with different versions shouldn't be mixed, it may cause inappropriate Navigator's behaviour
        try FileManager.default.createDirectory(at: tilesURL, withIntermediateDirectories: true, attributes: nil)
        let params = RouterParams(tilesPath: tilesURL.path, inMemoryTileCache: nil, mapMatchingSpatialCache: nil, threadsCount: nil, endpointConfig: endpointConfig)
        
        proxyDelegate?.navNative?.configureRouter(for: params)
    }

    public func updateLocation(_ location: CLLocation?) {
        guard let location = location else { return }
        stopUpdatingLocation()
        stopUpdatingHeading()
        proxyDelegate?.locationManager(self, didUpdateLocations: [location])
    }

    override public var delegate: CLLocationManagerDelegate? {
        get {
            proxyDelegate?.delegate
        }
        set {
            proxyDelegate?.delegate = newValue
        }
    }

    private class ProxyDelegate: NSObject, CLLocationManagerDelegate {
        var navNative: Navigator?
        var delegate: CLLocationManagerDelegate?
        weak var debugDelegate: FreeDriveDebugInfoListener?

        required init(navigator: Navigator? = nil) {
            self.navNative = navigator
            super.init()
        }

        deinit {
            self.navNative = nil
        }

        // MARK: CLLocationManagerDelegate

        public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let loc = locations.first {
                navNative?.updateLocation(for: FixLocation(loc))
                let projectedDate = Date()
                if let status = navNative?.getStatusForTimestamp(projectedDate) {
                    delegate?.locationManager?(manager, didUpdateLocations: [CLLocation(status.location)])

                    debugDelegate?.didGet(location: CLLocation(status.location), with: status.map_matcher_output.matches, for: loc)
                } else {
                    delegate?.locationManager?(manager, didUpdateLocations: locations)
                }
            }
        }

        public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            delegate?.locationManager?(manager, didUpdateHeading: newHeading)
        }

        public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
            return delegate?.locationManagerShouldDisplayHeadingCalibration?(manager) ?? false
        }

        public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            delegate?.locationManager?(manager, didFailWithError: error)
        }
    }
}

extension TileEndpointConfiguration {
    convenience init(directions: Directions, tilesVersion: String) {
        let host = directions.credentials.host.absoluteString
        guard let accessToken = directions.credentials.accessToken, !accessToken.isEmpty else {
            preconditionFailure("No access token specified in Info.plist")
        }
        let skuTokenProvider = SkuTokenProvider(with: directions.credentials)
        self.init(host: host, version: tilesVersion, token: accessToken, userAgent: URLSession.userAgent, navigatorVersion: "", skuTokenSource: skuTokenProvider)
    }
}
