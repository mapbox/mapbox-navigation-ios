import _MapboxNavigationHelpers
import Foundation
import MapboxCommon
import MapboxCommon_Private
import MapboxDirections
import MapboxNavigationNative
import MapboxNavigationNative_Private

public let customConfigKey = "com.mapbox.navigation.custom-config"
public let customConfigFeaturesKey = "features"

/// Internal class, designed for handling initialisation of various NavigationNative entities.
///
/// Such entities might be used not only as a part of Navigator init sequece, so it is meant not to rely on it's
/// settings.
final class NativeHandlersFactory: @unchecked Sendable {
    // MARK: - Settings

    let tileStorePath: String
    let apiConfiguration: ApiConfiguration
    let tilesVersion: String
    let targetVersion: String?
    let configFactoryType: ConfigFactory.Type
    let datasetProfileIdentifier: ProfileIdentifier
    let routingProviderSource: MapboxNavigationNative.RouterType?

    let liveIncidentsOptions: IncidentsConfig?
    let navigatorPredictionInterval: TimeInterval?
    let statusUpdatingSettings: StatusUpdatingSettings?
    let utilizeSensorData: Bool
    let historyDirectoryURL: URL?

    init(
        tileStorePath: String,
        apiConfiguration: ApiConfiguration,
        tilesVersion: String,
        targetVersion: String? = nil,
        configFactoryType: ConfigFactory.Type = ConfigFactory.self,
        datasetProfileIdentifier: ProfileIdentifier,
        routingProviderSource: MapboxNavigationNative.RouterType? = nil,
        liveIncidentsOptions: IncidentsConfig?,
        navigatorPredictionInterval: TimeInterval?,
        statusUpdatingSettings: StatusUpdatingSettings? = nil,
        utilizeSensorData: Bool,
        historyDirectoryURL: URL?
    ) {
        self.tileStorePath = tileStorePath
        self.apiConfiguration = apiConfiguration
        self.tilesVersion = tilesVersion
        self.targetVersion = targetVersion
        self.configFactoryType = configFactoryType
        self.datasetProfileIdentifier = datasetProfileIdentifier
        self.routingProviderSource = routingProviderSource

        self.liveIncidentsOptions = liveIncidentsOptions
        self.navigatorPredictionInterval = navigatorPredictionInterval
        self.statusUpdatingSettings = statusUpdatingSettings
        self.utilizeSensorData = utilizeSensorData
        self.historyDirectoryURL = historyDirectoryURL
    }

    func targeting(version: String?) -> NativeHandlersFactory {
        return .init(
            tileStorePath: tileStorePath,
            apiConfiguration: apiConfiguration,
            tilesVersion: tilesVersion,
            targetVersion: version,
            configFactoryType: configFactoryType,
            datasetProfileIdentifier: datasetProfileIdentifier,
            routingProviderSource: routingProviderSource,
            liveIncidentsOptions: liveIncidentsOptions,
            navigatorPredictionInterval: navigatorPredictionInterval,
            statusUpdatingSettings: statusUpdatingSettings,
            utilizeSensorData: utilizeSensorData,
            historyDirectoryURL: historyDirectoryURL
        )
    }

    // MARK: - Native Handlers

    lazy var historyRecorderHandle: HistoryRecorderHandle? = onMainQueueSync {
        historyDirectoryURL.flatMap {
            HistoryRecorderHandle.build(
                forHistoryDir: $0.path,
                config: configHandle(by: configFactoryType)
            )
        }
    }

    lazy var navigator: NavigationNativeNavigator = onMainQueueSync {
        // Make sure that Navigator pick ups Main Thread RunLoop.
        let historyRecorder = historyRecorderHandle
        let configHandle = configHandle(by: configFactoryType)

        let router = routingProviderSource.map {
            MapboxNavigationNative.RouterFactory.build(
                for: $0,
                cache: cacheHandle,
                config: configHandle,
                historyRecorder: historyRecorder
            )
        }
        return .init(
            navigator: MapboxNavigationNative.Navigator(
                config: configHandle,
                cache: cacheHandle,
                historyRecorder: historyRecorder,
                router: router
            )
        )
    }

    lazy var cacheHandle: CacheHandle = cacheHandlerFactory.getHandler(
        with: (
            tilesConfig: tilesConfig,
            configHandle: configHandle(by: configFactoryType),
            historyRecorder: historyRecorderHandle
        ),
        cacheData: self
    )

    lazy var roadGraph: RoadGraph = .init(MapboxNavigationNative.GraphAccessor(cache: cacheHandle))

    lazy var tileStore: TileStore = .__create(forPath: tileStorePath)

    // MARK: - Support Objects

    static var settingsProfile: SettingsProfile {
        SettingsProfile(
            application: .mobile,
            platform: .IOS
        )
    }

    lazy var endpointConfig: TileEndpointConfiguration = .init(
        apiConfiguration: apiConfiguration,
        tilesVersion: tilesVersion,
        minimumDaysToPersistVersion: nil,
        targetVersion: targetVersion,
        datasetProfileIdentifier: datasetProfileIdentifier
    )

    lazy var tilesConfig: TilesConfig = .init(
        tilesPath: tileStorePath,
        tileStore: tileStore,
        inMemoryTileCache: nil,
        onDiskTileCache: nil,
        endpointConfig: endpointConfig
    )

    var navigatorConfig: NavigatorConfig {
        var nativeIncidentsOptions: MapboxNavigationNative.IncidentsOptions?
        if let incidentsOptions = liveIncidentsOptions,
           !incidentsOptions.graph.isEmpty
        {
            nativeIncidentsOptions = .init(
                graph: incidentsOptions.graph,
                apiUrl: incidentsOptions.apiURL?.absoluteString ?? ""
            )
        }

        var pollingConfig: PollingConfig? = nil

        if let predictionInterval = navigatorPredictionInterval {
            pollingConfig = PollingConfig(
                lookAhead: NSNumber(value: predictionInterval),
                unconditionalPatience: nil,
                unconditionalInterval: nil
            )
        }
        if let config = statusUpdatingSettings {
            if pollingConfig != nil {
                pollingConfig?.unconditionalInterval = config.updatingInterval.map { NSNumber(value: $0) }
                pollingConfig?.unconditionalPatience = config.updatingPatience.map { NSNumber(value: $0) }
            } else if config.updatingPatience != nil || config.updatingInterval != nil {
                pollingConfig = PollingConfig(
                    lookAhead: nil,
                    unconditionalPatience: config.updatingPatience
                        .map { NSNumber(value: $0) },
                    unconditionalInterval: config.updatingInterval
                        .map { NSNumber(value: $0) }
                )
            }
        }

        return NavigatorConfig(
            voiceInstructionThreshold: nil,
            electronicHorizonOptions: nil,
            polling: pollingConfig,
            incidentsOptions: nativeIncidentsOptions,
            noSignalSimulationEnabled: nil,
            avoidManeuverSeconds: NSNumber(value: RerouteController.DefaultManeuverAvoidanceRadius),
            useSensors: NSNumber(booleanLiteral: utilizeSensorData)
        )
    }

    func configHandle(by configFactoryType: ConfigFactory.Type = ConfigFactory.self) -> ConfigHandle {
        let defaultConfig = [
            customConfigFeaturesKey: [
                "useInternalReroute": true,
                "useTelemetryNavigationEvents": true,
            ],
        ]

        var customConfig = UserDefaults.standard.dictionary(forKey: customConfigKey) ?? [:]
        customConfig.deepMerge(with: defaultConfig, uniquingKeysWith: { first, _ in first })

        let customConfigJSON: String
        if let jsonDataConfig = try? JSONSerialization.data(withJSONObject: customConfig, options: []),
           let encodedConfig = String(data: jsonDataConfig, encoding: .utf8)
        {
            customConfigJSON = encodedConfig
        } else {
            assertionFailure("Custom config can not be serialized")
            customConfigJSON = ""
        }

        return configFactoryType.build(
            for: Self.settingsProfile,
            config: navigatorConfig,
            customConfig: customConfigJSON
        )
    }

    @MainActor
    func telemetry(eventsMetadataProvider: EventsMetadataInterface) -> Telemetry {
        navigator.native.getTelemetryForEventsMetadataProvider(eventsMetadataProvider)
    }
}

extension TileEndpointConfiguration {
    /**
     Initializes an object that configures a navigator to obtain routing tiles of the given version from an endpoint, using the given credentials.

           - parameter apiConfiguration: ApiConfiguration for accessing road network data.
           - parameter tilesVersion: Routing tile version.
           - parameter minimumDaysToPersistVersion: The minimum age in days that a tile version much reach before a new version can be requested from the tile endpoint.
           - parameter targetVersion: Routing tile version, which navigator would like to eventually switch to if it becomes available
           - parameter datasetProfileIdentifier: profile setting, used for selecting tiles type for navigation.
     */
    convenience init(
        apiConfiguration: ApiConfiguration,
        tilesVersion: String,
        minimumDaysToPersistVersion: Int?,
        targetVersion: String?,
        datasetProfileIdentifier: ProfileIdentifier
    ) {
        self.init(
            host: apiConfiguration.endPoint.absoluteString,
            dataset: datasetProfileIdentifier.rawValue,
            version: tilesVersion,
            isFallback: targetVersion != nil,
            versionBeforeFallback: targetVersion ?? tilesVersion,
            minDiffInDaysToConsiderServerVersion: minimumDaysToPersistVersion as NSNumber?
        )
    }
}
