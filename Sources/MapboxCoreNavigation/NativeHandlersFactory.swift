import MapboxNavigationNative
import MapboxDirections


/// Internal class, designed for handling initialisation of various NavigationNative entities.
///
/// Such entities might be used not only as a part of Navigator init sequece, so it is meant not to rely on it's settings.
class NativeHandlersFactory {
    
    // MARK: - Settings
    
    let tileStorePath: String
    let credentials: DirectionsCredentials
    let tilesVersion: String?
    let historyDirectoryURL: URL?
    let targetVersion: String?
    
    init(tileStorePath: String,
         credentials: DirectionsCredentials = Directions.shared.credentials,
         tilesVersion: String? = nil,
         historyDirectoryURL: URL? = nil,
         targetVersion: String? = nil) {
        self.tileStorePath = tileStorePath
        self.credentials = credentials
        self.tilesVersion = tilesVersion
        self.historyDirectoryURL = historyDirectoryURL
        self.targetVersion = targetVersion
    }
    
    // MARK: - Native Handlers
    
    lazy var historyRecorder: HistoryRecorderHandle? = {
        historyDirectoryURL.flatMap {
            HistoryRecorderHandle.build(forHistoryDir: $0.path, config: configHandle)
        }
    }()
    
    lazy var navigator: MapboxNavigationNative.Navigator = {
        MapboxNavigationNative.Navigator(config: configHandle,
                                         runLoopExecutor: runloopExecutor,
                                         cache: cacheHandle,
                                         historyRecorder: historyRecorder)
    }()
    
    lazy var cacheHandle: CacheHandle = {
        CacheFactory.build(for: tilesConfig,
                           config: configHandle,
                           historyRecorder: historyRecorder)
    }()
    
    lazy var roadGraph: RoadGraph = {
        RoadGraph(MapboxNavigationNative.GraphAccessor(cache: cacheHandle))
    }()
    
    lazy var tileStore: TileStore = {
        TileStore.__create(forPath: tileStorePath)
    }()
    
    // MARK: - Support objects
    
    lazy var settingsProfile: SettingsProfile = {
        SettingsProfile(application: .mobile,
                        platform: .IOS)
    }()
    
    lazy var endpointConfig: TileEndpointConfiguration = {
        TileEndpointConfiguration(credentials: credentials,
                                  tilesVersion: tilesVersion ?? "",
                                  minimumDaysToPersistVersion: nil,
                                  targetVersion: targetVersion)
    }()
    
    lazy var tilesConfig: TilesConfig = {
        TilesConfig(tilesPath: tileStorePath,
                    tileStore: TileStore.__create(forPath: tileStorePath),
                    inMemoryTileCache: nil,
                    onDiskTileCache: nil,
                    mapMatchingSpatialCache: nil,
                    threadsCount: nil,
                    endpointConfig: endpointConfig)
    }()
    
    lazy var configHandle: ConfigHandle = {
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
        
        let navigatorConfig = NavigatorConfig(voiceInstructionThreshold: nil,
                                              electronicHorizonOptions: nil,
                                              polling: nil,
                                              incidentsOptions: nil,
                                              noSignalSimulationEnabled: nil)
        
        return  ConfigFactory.build(for: settingsProfile,
                                    config: navigatorConfig,
                                    customConfig: customConfig)
    }()
    
    lazy var runloopExecutor: RunLoopExecutorHandle = {
        RunLoopExecutorFactory.build()
    }()
}
