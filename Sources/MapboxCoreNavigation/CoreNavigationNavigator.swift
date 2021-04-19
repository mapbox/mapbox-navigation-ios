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
     A local path to the tiles storage location. If not specified - will be automatically defaulted
     to the cache subdirectory.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect.
     */
    static var tilesURL: URL? = nil
    
    /**
     Path to the file where history could be stored when `Navigator.dumpHistory(_:)` is called.
     */
    static var historyFilePath: URL? = nil
    
    /**
     Store history to the file stored in `Navigator.historyFilePath` and asynchronously run a callback
     when dumping finishes.
     
     - parameter completion: A block object to be executed when history dumping ends.
     */
    func dumpHistory(_ completion: @escaping (String?) -> Void) {
        historyRecorder.dumpHistory { (path) in
            completion(path)
        }
    }
    
    var historyRecorder: HistoryRecorderHandle!
    
    var navigator: MapboxNavigationNative.Navigator!
    
    var cacheHandle: CacheHandle!
    
    var roadGraph: RoadGraph!
    
    lazy var roadObjectsStore: RoadObjectsStore = {
        return RoadObjectsStore(navigator.roadObjectStore())
    }()
    
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
        var tilesPath: String! = Self.tilesURL?.path
        if tilesPath == nil {
            let bundle = Bundle.mapboxCoreNavigation
            if bundle.ensureSuggestedTileURLExists() {
                tilesPath = bundle.suggestedTileURL!.path
            } else {
                preconditionFailure("Failed to access cache storage.")
            }
        }
        
        let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile,
                                              platform: ProfilePlatform.KIOS)
        
        let endpointConfig = TileEndpointConfiguration(credentials:Navigator.credentials ?? Directions.shared.credentials,
                                                       tilesVersion: Self.tilesVersion,
                                                       minimumDaysToPersistVersion: nil)
        
        let tilesConfig = TilesConfig(tilesPath: tilesPath,
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
        
        historyRecorder = HistoryRecorderHandle.build(forHistoryFile: Navigator.historyFilePath?.absoluteString ?? "", config: configFactory)
        
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
        let userInfo: [ElectronicHorizon.NotificationUserInfoKey: Any] = [
            .positionKey: RoadGraph.Position(position.position()),
            .treeKey: ElectronicHorizon(position.tree()),
            .updatesMostProbablePathKey: position.type() == .UPDATE,
            .distancesByRoadObjectKey: distances.mapValues(RoadObjectDistanceInfo.init),
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidUpdatePosition, object: nil, userInfo: userInfo)
    }
    
    public func onRoadObjectEnter(for info: RoadObjectEnterExitInfo) {
        let userInfo: [ElectronicHorizon.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
            .didTransitionAtEndpointKey: info.isEnterFromStartOrExitFromEnd,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidEnterRoadObject, object: nil, userInfo: userInfo)
    }
    
    public func onRoadObjectExit(for info: RoadObjectEnterExitInfo) {
        let userInfo: [ElectronicHorizon.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
            .didTransitionAtEndpointKey: info.isEnterFromStartOrExitFromEnd,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidExitRoadObject, object: nil, userInfo: userInfo)
    }
}
