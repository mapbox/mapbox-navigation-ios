import MapboxCommon
import MapboxNavigationNative
import MapboxDirections
import Foundation
@_implementationOnly import MapboxCommon_Private

public let customConfigKey = "com.mapbox.navigation.custom-config"
public let customConfigFeaturesKey = "features"

/// Internal class, designed for handling initialisation of various NavigationNative entities.
///
/// Such entities might be used not only as a part of Navigator init sequece, so it is meant not to rely on it's settings.
class NativeHandlersFactory {
    
    // MARK: - Settings
    
    let tileStorePath: String
    let credentials: Credentials
    let tilesVersion: String
    let targetVersion: String?
    let configFactoryType: ConfigFactory.Type
    let datasetProfileIdentifier: ProfileIdentifier
    let routingProviderSource: MapboxNavigationNative.RouterType?
    
    init(tileStorePath: String,
         credentials: Credentials,
         tilesVersion: String = "",
         targetVersion: String? = nil,
         configFactoryType: ConfigFactory.Type = ConfigFactory.self,
         datasetProfileIdentifier: ProfileIdentifier = ProfileIdentifier.automobile,
         routingProviderSource: MapboxNavigationNative.RouterType? = nil) {
        self.tileStorePath = tileStorePath
        self.credentials = credentials
        self.tilesVersion = tilesVersion
        self.targetVersion = targetVersion
        self.configFactoryType = configFactoryType
        self.datasetProfileIdentifier = datasetProfileIdentifier
        self.routingProviderSource = routingProviderSource
    }
    
    // MARK: - Native Handlers
    
    lazy var navigator: MapboxNavigationNative.Navigator = {
        onMainQueueSync { // Make sure that Navigator pick ups Main Thread RunLoop.
            let loggingLevel = NSNumber(value: LoggingLevel.info.rawValue)
            LogConfiguration.setLoggingLevelForUpTo(loggingLevel)
            
            let historyRecorder = HistoryRecorder.shared.handle
            let configHandle = Self.configHandle(by: configFactoryType)
            
            let router = routingProviderSource.map {
                MapboxNavigationNative.RouterFactory.build(for: $0,
                                                           cache: cacheHandle,
                                                           config: configHandle,
                                                           historyRecorder: historyRecorder)
            }
            return MapboxNavigationNative.Navigator(config: configHandle,
                                                    cache: cacheHandle,
                                                    historyRecorder: historyRecorder,
                                                    router: router)
        }
    }()
    
    lazy var cacheHandle: CacheHandle = {
        cacheHandlerFactory.getHandler(with: (tilesConfig: tilesConfig,
                                              configHandle: Self.configHandle(by: configFactoryType),
                                              historyRecorder: HistoryRecorder.shared.handle),
                                       cacheData: self)
    }()
    
    lazy var roadGraph: RoadGraph = {
        RoadGraph(MapboxNavigationNative.GraphAccessor(cache: cacheHandle))
    }()
    
    lazy var tileStore: TileStore = {
        TileStore.__create(forPath: tileStorePath)
    }()
    
    // MARK: - Support Objects
    
    static var settingsProfile: SettingsProfile {
        SettingsProfile(application: .mobile,
                        platform: .IOS)
    }
    
    lazy var endpointConfig: TileEndpointConfiguration = {
        TileEndpointConfiguration(credentials: credentials,
                                  tilesVersion: tilesVersion,
                                  minimumDaysToPersistVersion: nil,
                                  targetVersion: targetVersion,
                                  datasetProfileIdentifier: datasetProfileIdentifier)
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
    
    static var navigatorConfig: NavigatorConfig {
        var nativeIncidentsOptions: MapboxNavigationNative.IncidentsOptions?
        if let incidentsOptions = NavigationSettings.shared.liveIncidentsOptions,
           !incidentsOptions.graph.isEmpty {
            nativeIncidentsOptions = .init(graph: incidentsOptions.graph,
                                           apiUrl: incidentsOptions.apiURL?.absoluteString ?? "")
        }
        
        var pollingConfig: PollingConfig? = nil
        
        if let predictionInterval = NavigationSettings.shared.navigatorPredictionInterval {
            pollingConfig = PollingConfig(lookAhead: NSNumber(value:predictionInterval),
                                          unconditionalPatience: nil,
                                          unconditionalInterval: nil)
        }
        if let config = NavigationSettings.shared.statusUpdatingSettings {
            if pollingConfig != nil {
                pollingConfig?.unconditionalInterval = config.updatingInterval.map { NSNumber(value: $0) }
                pollingConfig?.unconditionalPatience = config.updatingPatience.map { NSNumber(value: $0) }
            } else if config.updatingPatience != nil || config.updatingInterval != nil {
                pollingConfig = PollingConfig(lookAhead: nil,
                                              unconditionalPatience: config.updatingPatience.map { NSNumber(value: $0) },
                                              unconditionalInterval: config.updatingInterval.map { NSNumber(value: $0) })
            }
        }
        
        return NavigatorConfig(voiceInstructionThreshold: nil,
                               electronicHorizonOptions: nil,
                               polling: pollingConfig,
                               incidentsOptions: nativeIncidentsOptions,
                               noSignalSimulationEnabled: nil,
                               avoidManeuverSeconds: NSNumber(value: RerouteController.DefaultManeuverAvoidanceRadius),
                               useSensors: NSNumber(booleanLiteral: NavigationSettings.shared.utilizeSensorData))
    }
    
    static func configHandle(by configFactoryType: ConfigFactory.Type = ConfigFactory.self) -> ConfigHandle {
        let defaultConfig = [
            customConfigFeaturesKey: [
                "useInternalReroute": true
            ]
        ]
        
        var customConfig = UserDefaults.standard.dictionary(forKey: customConfigKey) ?? [:]
        customConfig.deepMerge(with: defaultConfig, uniquingKeysWith: { first, _ in first })
                
        let customConfigJSON: String
        if let jsonDataConfig = try? JSONSerialization.data(withJSONObject: customConfig, options: []),
           let encodedConfig = String(data: jsonDataConfig, encoding: .utf8) {
            customConfigJSON = encodedConfig
        } else {
            assertionFailure("Custom config can not be serialized")
            customConfigJSON = ""
        }
        
        return configFactoryType.build(for: Self.settingsProfile,
                                       config: Self.navigatorConfig,
                                       customConfig: customConfigJSON)
    }
}
