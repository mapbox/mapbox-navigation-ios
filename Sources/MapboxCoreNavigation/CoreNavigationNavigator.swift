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
     Path to the directory where history file could be stored when `Navigator.writeHistory(completionHandler:)` is called.
     */
    static var historyDirectoryURL: URL? = nil
    
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
    
    var historyRecorder: HistoryRecorderHandle
    
    var navigator: MapboxNavigationNative.Navigator
    
    var cacheHandle: CacheHandle
    
    var roadGraph: RoadGraph
    
    lazy var roadObjectsStore: RoadObjectsStore = {
        return RoadObjectsStore(navigator.roadObjectStore())
    }()
    
    var tileStore: TileStore
    
    /**
     The Authorization & Authentication credentials that are used for this service. If not specified - will be automatically intialized from the token and host from your app's `info.plist`.
     
     - precondition: `credentials` should be set before getting the shared navigator for the first time.
     */
    static var credentials: DirectionsCredentials? = nil
    
    /**
     Provides a new or an existing `MapboxCoreNavigation.Navigator` instance. Upon first initialization will trigger creation of `MapboxNavigationNative.Navigator` and `HistoryRecorderHandle` instances,
     satisfying provided configuration (`tilesVersion` and `tilesURL`).
     */
    static let shared: Navigator = Navigator()
    
    /**
     Restrict direct initializer access.
     */
    private init() {
        let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile,
                                              platform: ProfilePlatform.KIOS)
        
        let endpointConfig = TileEndpointConfiguration(credentials:Navigator.credentials ?? Directions.shared.credentials,
                                                       tilesVersion: Self.tilesVersion,
                                                       minimumDaysToPersistVersion: nil)
        let tileStorePath = Self.tilesURL?.path ?? ""
        tileStore = TileStore.getInstanceForPath(tileStorePath)
        let tilesConfig = TilesConfig(tilesPath: tileStorePath,
                                      inMemoryTileCache: nil,
                                      onDiskTileCache: nil,
                                      mapMatchingSpatialCache: nil,
                                      threadsCount: nil,
                                      endpointConfig: endpointConfig)
        
        let historyAutorecordingConfig = [
            "features": [
                "historyAutorecording": true
            ]
        ]
        
        var customConfig = ""
        if let jsonDataConfig = try? JSONSerialization.data(withJSONObject: historyAutorecordingConfig, options: []),
           let encodedConfig = String(data: jsonDataConfig, encoding: .utf8) {
            customConfig = encodedConfig
        }
        
        let configFactory = ConfigFactory.build(for: settingsProfile,
                                                config: NavigatorConfig(),
                                                customConfig: customConfig)
        
        historyRecorder = HistoryRecorderHandle.build(forHistoryFile: Navigator.historyDirectoryURL?.absoluteString ?? "", config: configFactory)
        
        let runloopExecutor = RunLoopExecutorFactory.build()
        cacheHandle = CacheFactory.build(for: tilesConfig,
                                         config: configFactory,
                                         runLoop: runloopExecutor,
                                         historyRecorder: historyRecorder)
        
        roadGraph = RoadGraph(MapboxNavigationNative.GraphAccessor(cache: cacheHandle))
        
        navigator = MapboxNavigationNative.Navigator(config: configFactory,
                                                     runLoopExecutor: runloopExecutor,
                                                     cache: cacheHandle,
                                                     historyRecorder: historyRecorder)
        navigator.setElectronicHorizonObserverFor(self)
    }
    
    deinit {
        navigator.setElectronicHorizonObserverFor(nil)
    }
    
    var electronicHorizonOptions: ElectronicHorizonOptions? {
        didSet {
            let nativeOptions: MapboxNavigationNative.ElectronicHorizonOptions?
            if let electronicHorizonOptions = electronicHorizonOptions {
                nativeOptions = MapboxNavigationNative.ElectronicHorizonOptions(electronicHorizonOptions)
            } else {
                nativeOptions = nil
            }
            navigator.setElectronicHorizonOptionsFor(nativeOptions)
        }
    }
}

extension Navigator: ElectronicHorizonObserver {
    public func onPositionUpdated(for position: ElectronicHorizonPosition, distances: [String : MapboxNavigationNative.RoadObjectDistanceInfo]) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .positionKey: RoadGraph.Position(position.position()),
            .treeKey: try! position.tree(),
            .updatesMostProbablePathKey: position.type() == .UPDATE,
            .distancesByRoadObjectKey: distances.mapValues(RoadObjectDistanceInfo.init),
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
}
