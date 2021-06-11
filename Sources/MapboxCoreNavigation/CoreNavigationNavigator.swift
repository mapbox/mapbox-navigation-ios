import MapboxNavigationNative
import MapboxDirections

class Navigator {
    
    /**
     Tiles version string. If not specified explicitly - will be automatically resolved
     to the latest version.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect.
     */
    static var tilesVersion: String = ""
    
    /**
     A local path to the tiles storage location. If not specified - will be automatically set to a default location.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect. After initialisation, use `tileStore` to get correponding instance.
     */
    static var tilesURL: URL? = nil
    
    /**
     Path to the directory where history file could be stored when `Navigator.writeHistory(completionHandler:)` is called. Defaults to user support directory.
     */
    static var historyDirectoryURL: URL = {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        return supportDir.appendingPathComponent("com.mapbox.navigation.history")
    }()
    
    /**
     Store history to the directory stored in `Navigator.historyDirectoryURL` and asynchronously run a callback
     when writing finishes.
     
     - parameter completionHandler: A block object to be executed when history dumping ends.
     */
    func writeHistory(completionHandler: @escaping (URL?) -> Void) {
        historyRecorder.dumpHistory { (path) in
            if let path = path {
                completionHandler(URL(fileURLWithPath: path))
            } else {
                completionHandler(nil)
            }
        }
    }
    
    private(set) var historyRecorder: HistoryRecorderHandle
    
    private(set) var navigator: MapboxNavigationNative.Navigator
    
    private(set) var cacheHandle: CacheHandle
    
    private(set) var roadGraph: RoadGraph
    
    lazy var router: MapboxNavigationNative.Router = {
        return MapboxNavigationNative.Router(cache: cacheHandle,
                                             historyRecorder: historyRecorder)
    }()

    private(set) var roadObjectStore: RoadObjectStore

    private(set) var roadObjectMatcher: RoadObjectMatcher

    private(set) var tileStore: TileStore
    
    /**
     Current Navigator status in terms of tile versioning.
     */
    private(set) var tileVersionState: TileVersionState
    
    /**
     The Authorization & Authentication credentials that are used for this service. If not specified - will be automatically intialized from the token and host from your app's `info.plist`.
     
     - precondition: `credentials` should be set before getting the shared navigator for the first time.
     */
    static var credentials: DirectionsCredentials? = nil
    
    /**
     Provides a new or an existing `MapboxCoreNavigation.Navigator` instance. Upon first initialization will trigger creation of `MapboxNavigationNative.Navigator` and `HistoryRecorderHandle` instances,
     satisfying provided configuration (`tilesVersion` and `tilesURL`).
     */
    static var shared: Navigator {
        return _navigator
    }
    
    // Used in tests to recreate the navigator
    static var _navigator: Navigator = .init()
    
    static func _recreateNavigator() { _navigator = .init() }
    
    /**
     Restrict direct initializer access.
     */
    private init() {
        let factory = NativeHandlersFactory(tileStorePath: Self.tilesURL?.path ?? "",
                                            credentials: Self.credentials ?? Directions.shared.credentials,
                                            tilesVersion: Self.tilesVersion,
                                            historyDirectoryURL: Self.historyDirectoryURL)
        tileVersionState = .nominal
        tileStore = factory.tileStore
        historyRecorder = factory.historyRecorder
        cacheHandle = factory.cacheHandle
        roadGraph = factory.roadGraph
        navigator = factory.navigator
        roadObjectStore = RoadObjectStore(navigator.roadObjectStore())
        roadObjectMatcher = RoadObjectMatcher(MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle))
        
        subscribeNavigator()
    }

    /**
     Destroys and creates new instance of Navigator together with other related entities.
     
     Typically, this method is used to restart a Navigator with a specific Version during switching to offline or online modes.
     - parameter version: String representing a tile version name. `nil` value means "latest". Specifying exact version also enables `fallback` mode which will passively monitor newer version available and will notify `tileVersionState` if found.
     */
    func restartNavigator(forcing version: String? = nil) {
        unsubscribeNavigator()
        tileVersionState = .nominal
        navigator.shutdown()
        
        let factory = NativeHandlersFactory(tileStorePath: Self.tilesURL?.path ?? "",
                                            credentials: Self.credentials ?? Directions.shared.credentials,
                                            tilesVersion: version ?? Self.tilesVersion,
                                            historyDirectoryURL: Self.historyDirectoryURL,
                                            targetVersion: version.map { _ in Self.tilesVersion })
        tileStore = factory.tileStore
        historyRecorder = factory.historyRecorder
        cacheHandle = factory.cacheHandle
        roadGraph = factory.roadGraph
        navigator = factory.navigator
        
        roadObjectStore.native = navigator.roadObjectStore()
        roadObjectMatcher.native = MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle)
        setupElectronicHorizonOptions()
        
        subscribeNavigator()
    }
    
    private func subscribeNavigator() {
        navigator.setElectronicHorizonObserverFor(self)
        navigator.addObserver(for: self)
        navigator.setFallbackVersionsObserverFor(self)
    }
    
    private func unsubscribeNavigator() {
        navigator.setElectronicHorizonObserverFor(nil)
        navigator.removeObserver(for: self)
        navigator.setFallbackVersionsObserverFor(nil)
    }
     
    private func setupElectronicHorizonOptions() {
        let nativeOptions = electronicHorizonOptions.map(MapboxNavigationNative.ElectronicHorizonOptions.init)
        
        navigator.setElectronicHorizonOptionsFor(nativeOptions)
    }
    
    deinit {
        unsubscribeNavigator()
    }
    
    var electronicHorizonOptions: ElectronicHorizonOptions? {
        didSet {
            setupElectronicHorizonOptions()
        }
    }
}

extension Navigator: FallbackVersionsObserver {
    
    enum TileVersionState {
        /// No tiles version switch is required. Navigator has enough tiles for map matching.
        case nominal
        /// Navigator does not have tiles on current version for map matching, but TileStore contains regions with required tiles of a different version
        case shouldFallback([String])
        /// Navigator is in a fallback mode but newer tiles version were successefully downloaded and ready to use.
        case shouldReturnToLatest
    }
    
    func onFallbackVersionsFound(forVersions versions: [String]) {
        DispatchQueue.main.async { [self] in
            switch tileVersionState {
            case .nominal, .shouldReturnToLatest:
                tileVersionState = .shouldFallback(versions)
                guard let fallbackVersion = versions.last else { return }
                
                Navigator.shared.restartNavigator(forcing: fallbackVersion)
                
                let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
                    .tilesVersionKey: fallbackVersion
                ]
                
                NotificationCenter.default.post(name: .navigationDidSwitchToFallbackVersion,
                                                object: nil,
                                                userInfo: userInfo)
            case .shouldFallback:
                break // do nothing
            }
        }
    }

    func onCanReturnToLatest(forVersion version: String) {
        DispatchQueue.main.async { [self] in
            switch tileVersionState {
            case .nominal, .shouldFallback:
                tileVersionState = .shouldReturnToLatest
                Navigator.shared.restartNavigator(forcing: nil)
                
                let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
                    .tilesVersionKey: version
                ]
                
                NotificationCenter.default.post(name: .navigationDidSwitchToTargetVersion,
                                                object: nil,
                                                userInfo: userInfo)
            case .shouldReturnToLatest:
                break // do nothing
            }
        }
    }
}

extension Navigator: ElectronicHorizonObserver {
    public func onPositionUpdated(for position: ElectronicHorizonPosition, distances: [MapboxNavigationNative.RoadObjectDistance]) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .positionKey: RoadGraph.Position(position.position()),
            .treeKey: RoadGraph.Edge(position.tree().start),
            .updatesMostProbablePathKey: position.type() == .update,
            .distancesByRoadObjectKey: distances.map(DistancedRoadObject.init),
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidUpdatePosition, object: nil, userInfo: userInfo)
    }
    
    public func onRoadObjectEnter(for info: RoadObjectEnterExitInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
            .didTransitionAtEndpointKey: info.isEnterFromStartOrExitFromEnd,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidEnterRoadObject, object: nil, userInfo: userInfo)
    }
    
    public func onRoadObjectExit(for info: RoadObjectEnterExitInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
            .didTransitionAtEndpointKey: info.isEnterFromStartOrExitFromEnd,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidExitRoadObject, object: nil, userInfo: userInfo)
    }

    public func onRoadObjectPassed(for info: RoadObjectPassInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidPassRoadObject, object: nil, userInfo: userInfo)
    }
}

extension Navigator: NavigatorObserver {
    func onStatus(for origin: NavigationStatusOrigin, status: NavigationStatus) {
        guard origin == .locationUpdate else { return }
        let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
            .originKey: origin,
            .statusKey: status,
        ]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
    }
}
