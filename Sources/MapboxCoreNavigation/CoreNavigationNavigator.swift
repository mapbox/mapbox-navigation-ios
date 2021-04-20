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
    
    func enableHistoryRecorder() throws {
        try historyRecorder.enable(forEnabled: true)
    }
    
    func disableHistoryRecorder() throws {
        try historyRecorder.enable(forEnabled: false)
    }
    
    func history() throws -> Data {
        return try historyRecorder.getHistory()
    }
    
    var historyRecorder: HistoryRecorderHandle!
    
    var navigator: MapboxNavigationNative.Navigator!
    
    var cacheHandle: CacheHandle!
    
    var roadGraph: RoadGraph!
    
    lazy var roadObjectsStore: RoadObjectsStore = {
        return RoadObjectsStore(try! navigator.roadObjectStore())
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
        
        let configFactory = try! ConfigFactory.build(for: settingsProfile,
                                                     config: NavigatorConfig(),
                                                     customConfig: "")
        
        historyRecorder = try! HistoryRecorderHandle.build(forHistoryFile: "", config: configFactory)
        
        let runloopExecutor = try! RunLoopExecutorFactory.build()
        cacheHandle = try! CacheFactory.build(for: tilesConfig,
                                              config: configFactory,
                                              runLoop: runloopExecutor,
                                              historyRecorder: historyRecorder)
        
        roadGraph = RoadGraph(try! MapboxNavigationNative.GraphAccessor(cache: cacheHandle))
        
        navigator = try! MapboxNavigationNative.Navigator(config: configFactory,
                                                          runLoopExecutor: runloopExecutor,
                                                          cache: cacheHandle,
                                                          historyRecorder: historyRecorder)
        try! navigator.setElectronicHorizonObserverFor(self)
    }
    
    deinit {
        try! navigator.setElectronicHorizonObserverFor(nil)
    }
    
    var electronicHorizonOptions: ElectronicHorizonOptions? {
        didSet {
            let nativeOptions: MapboxNavigationNative.ElectronicHorizonOptions?
            if let electronicHorizonOptions = electronicHorizonOptions {
                nativeOptions = MapboxNavigationNative.ElectronicHorizonOptions(electronicHorizonOptions)
            } else {
                nativeOptions = nil
            }
            try! navigator.setElectronicHorizonOptionsFor(nativeOptions)
        }
    }
    
    var peer: MBXPeerWrapper?
}

extension Navigator: ElectronicHorizonObserver {
    public func onPositionUpdated(for position: ElectronicHorizonPosition, distances: [String : MapboxNavigationNative.RoadObjectDistanceInfo]) {
        var userInfo: [ElectronicHorizon.NotificationUserInfoKey: Any] = [
            .positionKey: RoadGraph.Position(try! position.position()),
            .treeKey: ElectronicHorizon(try! position.tree()),
            .updatesMostProbablePathKey: try! position.type() == .UPDATE,
            .distancesByRoadObjectKey: distances.mapValues(RoadObjectDistanceInfo.init),
        ]
        if let roadGraph = roadGraph {
            userInfo.updateValue(roadGraph, forKey: .roadGraphIdentifierKey)
        }
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
