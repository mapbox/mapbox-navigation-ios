import MapboxNavigationNative
import CoreLocation
import Mapbox
import MapboxAccounts

func createNavigator(withTilesVersion tilesVersion: String = "2020_03_07-03_00_00") -> Navigator {
    let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
    let navigator = Navigator(profile: settingsProfile, customConfig: "")
    let host = "https://api-routing-tiles-here-staging.tilestream.net"
    let publicToken = ""
    assert(publicToken != "")
    let endpointConfig = TileEndpointConfiguration(
        host: host,
        version: tilesVersion,
        token: publicToken,
        userAgent: "MapboxNavigationNative",
        navigatorVersion: "14.1.0", skuTokenSource: Accounts()
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

open class FreeDriveLocationManager: NavigationLocationManager, CLLocationManagerDelegate {
    private var proxyDelegate: ProxyDelegate
    public required init(navigator: Navigator? = nil) {
        let resolvedNavigator: Navigator
        if let navigator = navigator {
            resolvedNavigator = navigator
        } else {
            resolvedNavigator = createNavigator()
        }
        proxyDelegate = ProxyDelegate(navigator: resolvedNavigator)

        super.init()

        super.delegate = proxyDelegate
    }

    func setCustomLocation(_ location: CLLocation?) {
        guard let location = location else { return }
        stopUpdatingLocation()
        stopUpdatingHeading()
        proxyDelegate.locationManager(self, didUpdateLocations: [location])
    }

    // MARK: MGLLocationManager

    override public var delegate: CLLocationManagerDelegate? {
        get {
            proxyDelegate.delegate
        }
        set {
            proxyDelegate.delegate = newValue
        }
    }

    public func debugView(onUpdated: ((CLLocationCoordinate2D, CLLocationCoordinate2D)->Void)?) -> UIView {
        let debugView = FreeDriveDebugInfoView()
        proxyDelegate.debugDelegate = debugView
        debugView.onUpdated = onUpdated
        return debugView
    }

    private class ProxyDelegate: NSObject, CLLocationManagerDelegate {
        private var navNative: Navigator!
        var delegate: CLLocationManagerDelegate?
        weak var debugDelegate: FreeDriveDebugInfoListener?

        required init(navigator: Navigator? = nil) {
            self.navNative = navigator ?? Navigator()
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
                let status = navNative.getStatusForTimestamp(projectedDate)
                delegate?.locationManager?(manager, didUpdateLocations: [CLLocation(status.location)])

                debugDelegate?.didGet(location: CLLocation(status.location), with: status.map_matcher_output.matches, for: loc)
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

private class Accounts: SkuTokenSource {
    init() {
        MBXAccounts.activateSKUID(.navigationUser)
    }
    func getToken() -> String {
        MBXAccounts.skuToken
    }

    var peer: MBXPeerWrapper?
}

protocol FreeDriveDebugInfoListener: AnyObject {
    func didGet(location: CLLocation, with matches: [MapMatch], for rawLocation: CLLocation)
}

class FreeDriveDebugInfoView: UIView, FreeDriveDebugInfoListener, UITableViewDataSource, UITableViewDelegate {
    private let rawLocationLabel: UILabel
    private let locationLabel: UILabel
    private let matchesTable: UITableView
    private var matches: [MapMatch] = []
    var onUpdated: ((CLLocationCoordinate2D, CLLocationCoordinate2D)->Void)?

    init() {
        rawLocationLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 15))
        locationLabel = UILabel(frame: CGRect(x: 0, y: 15, width: 200, height: 15))
        matchesTable = UITableView(frame: CGRect(x: 0, y: 30, width: 200, height: 120))
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 200),
            heightAnchor.constraint(equalToConstant: 150)
        ])
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(rawLocationLabel)
        addSubview(locationLabel)
        rawLocationLabel.font = UIFont.systemFont(ofSize: 9)
        locationLabel.font = UIFont.systemFont(ofSize: 9)

        addSubview(matchesTable)
        matchesTable.dataSource = self
        matchesTable.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didGet(location: CLLocation, with matches: [MapMatch], for rawLocation: CLLocation) {
        //TODO: implement
        rawLocationLabel.text = String(format: "RawLoc: %.8f, %.8f", rawLocation.coordinate.latitude, rawLocation.coordinate.longitude)
        locationLabel.text = String(format: "Loc: %.8f, %.8f", location.coordinate.latitude, location.coordinate.longitude)
        self.matches = matches
        matchesTable.reloadData()
        onUpdated?(rawLocation.coordinate, location.coordinate)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? matches.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "Match with probability: \(matches[indexPath.row].proba)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 9)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 15
    }
}
