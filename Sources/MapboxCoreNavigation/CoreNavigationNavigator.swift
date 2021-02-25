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
    
    var graphAccessor: GraphAccessor!
    
    /**
     Provides a new or an existing `MapboxCoreNavigation.Navigator` instance. Upon first initialization will trigger creation of `MapboxNavigationNative.Navigator` and `HistoryRecorderHandle` instances,
     satisfying provided configuration (`tilesVersion` and `tilesURL`).
     */
    static let shared: Navigator = {
        let instance = Navigator()
        
        var tilesPath: String! = tilesURL?.path
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
        
        let endpointConfig = TileEndpointConfiguration(credentials: Directions.shared.credentials,
                                                       tilesVersion: tilesVersion,
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
        
        instance.historyRecorder = try! HistoryRecorderHandle.build(forHistoryFile: "",
                                                                    config: configFactory)
        
        let runloopExecutor = try! RunLoopExecutorFactory.build()
        instance.cacheHandle = try! CacheFactory.build(for: tilesConfig,
                                                       config: configFactory,
                                                       runLoop: runloopExecutor,
                                                       historyRecorder: instance.historyRecorder)
        
        instance.graphAccessor = try! GraphAccessor(cache: instance.cacheHandle)
        
        instance.navigator = try! MapboxNavigationNative.Navigator(config: configFactory,
                                                                   runLoopExecutor: runloopExecutor,
                                                                   cache: instance.cacheHandle,
                                                                   historyRecorder: instance.historyRecorder)
        
        return instance
    }()
    
    /**
     Restrict direct initializer access.
     */
    private init() {
        
    }
}
