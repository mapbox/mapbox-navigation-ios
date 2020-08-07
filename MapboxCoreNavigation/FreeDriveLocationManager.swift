import MapboxNavigationNative
import CoreLocation
import MapboxDirections
import Mapbox
import MapboxAccounts

public protocol FreeDriveDebugInfoListener: AnyObject {
    func didGet(location: CLLocation, with matches: [MapMatch], for rawLocation: CLLocation)
}

open class FreeDriveLocationManager: NavigationLocationManager, CLLocationManagerDelegate {
    public weak var debugInfoListener: FreeDriveDebugInfoListener? {
        get {
            proxyDelegate?.debugDelegate
        }
        set {
            proxyDelegate?.debugDelegate = newValue
        }
    }

    private var proxyDelegate: ProxyDelegate?

    public required init(navigator: Navigator? = nil) {
        proxyDelegate = ProxyDelegate()
        super.init()

        if let navigator = navigator {
            proxyDelegate?.navNative = navigator
        } else {
            let tilesVersion = RouteTilesVersion(with: Directions.shared.credentials)
            tilesVersion.getAvailableVersions { availableVersions in
                if let latestVersion = availableVersions.last {
                    tilesVersion.currentVersion = latestVersion
                    let navigator = self.createNavigator(withTilesVersion: latestVersion)
                    self.proxyDelegate?.navNative = navigator
                }
            }
        }

        super.delegate = proxyDelegate
    }

    private func createNavigator(withTilesVersion tilesVersion: String) -> Navigator {
        let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
        let navigator = Navigator(profile: settingsProfile, config: NavigatorConfig() , customConfig: "")
        let host = Directions.shared.credentials.host.absoluteString
        let publicToken = Directions.shared.credentials.accessToken ?? ""
        assert(publicToken != "")
        let endpointConfig = TileEndpointConfiguration(
            host: host,
            version: tilesVersion,
            token: publicToken,
            userAgent: "",
            navigatorVersion: "", skuTokenSource: SkuTokenProvider(with: DirectionsCredentials())
        )

        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            var tilesURL = cachesURL
            tilesURL.appendPathComponent(tilesVersion, isDirectory: true)
            do {
                // Tiles with different versions shouldn't be mixed, it may cause inappropriate Navigator's behaviour
                try FileManager.default.createDirectory(at: tilesURL, withIntermediateDirectories: true, attributes: nil)
                let params = RouterParams(tilesPath: tilesURL.path, inMemoryTileCache: nil, mapMatchingSpatialCache: nil, threadsCount: nil, endpointConfig: endpointConfig)

                navigator.configureRouter(for: params)
            } catch {
                assert(false, "Couldn't create cache directory for tiles")
            }
        } else {
            assert(false, "Couldn't create cache directory for tiles")
        }
        return navigator
    }

    func setCustomLocation(_ location: CLLocation?) {
        guard let location = location else { return }
        stopUpdatingLocation()
        stopUpdatingHeading()
        proxyDelegate?.locationManager(self, didUpdateLocations: [location])
    }

    // MARK: MGLLocationManager

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
