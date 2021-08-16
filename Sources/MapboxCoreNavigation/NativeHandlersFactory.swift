import MapboxCommon
import MapboxNavigationNative
import MapboxDirections
import Foundation

public let customConfigKey = "com.mapbox.navigation.custom-config"
public let customConfigFeaturesKey = "features"

/// Internal class, designed for handling initialisation of various NavigationNative entities.
///
/// Such entities might be used not only as a part of Navigator init sequece, so it is meant not to rely on it's settings.
class NativeHandlersFactory {
    
    // MARK: - Settings
    
    let tileStorePath: String
    let credentials: Credentials
    let tilesVersion: String?
    let historyDirectoryURL: URL?
    let targetVersion: String?
    let configFactoryType: ConfigFactory.Type
    
    init(tileStorePath: String,
         credentials: Credentials,
         tilesVersion: String? = nil,
         historyDirectoryURL: URL? = nil,
         targetVersion: String? = nil,
         configFactoryType: ConfigFactory.Type = ConfigFactory.self) {
        self.tileStorePath = tileStorePath
        self.credentials = credentials
        self.tilesVersion = tilesVersion
        self.historyDirectoryURL = historyDirectoryURL
        self.targetVersion = targetVersion
        self.configFactoryType = configFactoryType
    }
    
    // MARK: - Native Handlers
    
    lazy var historyRecorder: HistoryRecorderHandle? = {
        historyDirectoryURL.flatMap {
            HistoryRecorderHandle.build(forHistoryDir: $0.path, config: configHandle)
        }
    }()
    
    lazy var navigator: MapboxNavigationNative.Navigator = {
        onMainQueueSync { // Make sure that Navigator pick ups Main Thread RunLoop.
            MapboxNavigationNative.Navigator(config: configHandle,
                                             cache: cacheHandle,
                                             historyRecorder: historyRecorder)
        }
    }()
    
    lazy var cacheHandle: CacheHandle = {
        CacheHandlerFactory.getHandler(for: tilesConfig,
                                       config: configHandle,
                                       historyRecorder: historyRecorder,
                                       cacheData: self)
    }()
    
    lazy var roadGraph: RoadGraph = {
        RoadGraph(MapboxNavigationNative.GraphAccessor(cache: cacheHandle))
    }()
    
    lazy var tileStore: TileStore = {
        TileStore.__create(forPath: tileStorePath)
    }()
    
    // MARK: - Support Objects
    
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
                    tileStore: tileStore,
                    inMemoryTileCache: nil,
                    onDiskTileCache: nil,
                    mapMatchingSpatialCache: nil,
                    threadsCount: nil,
                    endpointConfig: endpointConfig)
    }()
    
    lazy var configHandle: ConfigHandle = {
        let historyAutorecordingConfig = [
            customConfigFeaturesKey: [
                "historyAutorecording": true
            ]
        ]
        
        var customConfig = UserDefaults.standard.dictionary(forKey: customConfigKey) ?? [:]
        customConfig.deepMerge(with: historyAutorecordingConfig, uniquingKeysWith: { first, _ in first })
        
        let customConfigJSON: String
        if let jsonDataConfig = try? JSONSerialization.data(withJSONObject: customConfig, options: []),
           let encodedConfig = String(data: jsonDataConfig, encoding: .utf8) {
            customConfigJSON = encodedConfig
        } else {
            assertionFailure("Custom config can not be serialized")
            customConfigJSON = ""
        }
        
        let navigatorConfig = NavigatorConfig(voiceInstructionThreshold: nil,
                                              electronicHorizonOptions: nil,
                                              polling: nil,
                                              incidentsOptions: nil,
                                              noSignalSimulationEnabled: nil)
        
        return configFactoryType.build(for: settingsProfile,
                                       config: navigatorConfig,
                                       customConfig: customConfigJSON)
    }()
}
