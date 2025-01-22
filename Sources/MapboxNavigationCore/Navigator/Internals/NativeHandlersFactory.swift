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
    let initialManeuverAvoidanceRadius: TimeInterval
    var locale: Locale {
        didSet {
            _navigator?.locale = locale
        }
    }

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
        historyDirectoryURL: URL?,
        initialManeuverAvoidanceRadius: TimeInterval,
        locale: Locale
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
        self.initialManeuverAvoidanceRadius = initialManeuverAvoidanceRadius
        self.locale = locale
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
            historyDirectoryURL: historyDirectoryURL,
            initialManeuverAvoidanceRadius: initialManeuverAvoidanceRadius,
            locale: locale
        )
    }

    // MARK: - Native Handlers

    lazy var historyRecorderHandle: HistoryRecorderHandle? = onMainQueueSync {
        historyDirectoryURL.flatMap {
            HistoryRecorderHandle.build(
                forHistoryDir: $0.path,
                sdkInfo: SdkHistoryInfo(
                    sdkVersion: Bundle.mapboxNavigationVersion,
                    sdkName: Bundle.resolvedNavigationSDKName
                ),
                config: configHandle(by: configFactoryType)
            )
        }
    }

    private var _navigator: NavigationNativeNavigator?
    var navigator: NavigationNativeNavigator {
        if let _navigator {
            return _navigator
        }
        return onMainQueueSync {
            // Make sure that Navigator pick ups Main Thread RunLoop.
            let historyRecorder = historyRecorderHandle
            let configHandle = configHandle(by: configFactoryType)
            let navigator = if let routingProviderSource {
                MapboxNavigationNative.Navigator(
                    config: configHandle,
                    cache: cacheHandle,
                    historyRecorder: historyRecorder,
                    routerTypeRestriction: routingProviderSource
                )
            } else {
                MapboxNavigationNative.Navigator(
                    config: configHandle,
                    cache: cacheHandle,
                    historyRecorder: historyRecorder
                )
            }

            let nativeNavigator = NavigationNativeNavigator(navigator: navigator, locale: locale)
            self._navigator = nativeNavigator
            return nativeNavigator
        }
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
        endpointConfig: endpointConfig,
        hdEndpointConfig: nil
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
            useSensors: NSNumber(booleanLiteral: utilizeSensorData),
            rerouteStrategyForMatchRoute: .rerouteDisabled // TODO: support rerouteStrategyForMatchRoute
        )
    }

    func configHandle(by configFactoryType: ConfigFactory.Type = ConfigFactory.self) -> ConfigHandle {
        let defaultConfig = [
            customConfigFeaturesKey: [
                "useInternalReroute": true,
                "useInternalRouteRefresh": true,
                "useTelemetryNavigationEvents": true,
            ],
            "navigation": [
                "alternativeRoutes": [
                    "dropDistance": [
                        "maxSlightFork": 50.0,
                    ],
                ],
            ],
        ]

        var customConfig = UserDefaults.standard.dictionary(forKey: customConfigKey) ?? [:]
        customConfig.deepMerge(with: defaultConfig, uniquingKeysWith: { _, defaultConfigValue in defaultConfigValue })

        let customConfigJSON: String
        if let jsonDataConfig = try? JSONSerialization.data(withJSONObject: customConfig, options: [.sortedKeys]),
           let encodedConfig = String(data: jsonDataConfig, encoding: .utf8)
        {
            customConfigJSON = encodedConfig
        } else {
            assertionFailure("Custom config can not be serialized")
            customConfigJSON = ""
        }

        let configHandle = configFactoryType.build(
            for: Self.settingsProfile,
            config: navigatorConfig,
            customConfig: customConfigJSON
        )
        let avoidManeuverSeconds = NSNumber(value: initialManeuverAvoidanceRadius)
        configHandle.mutableSettings().setAvoidManeuverSecondsForSeconds(avoidManeuverSeconds)

        configHandle.mutableSettings().setUserLanguagesForLanguages(locale.preferredBCP47Codes)
        return configHandle
    }

    @MainActor
    func telemetry(eventsMetadataProvider: EventsMetadataInterface) -> Telemetry {
        // TODO: The Nav SDK annotates `native` as MainActor, but telemetry can be
        // sent from the background thread. We should create Telemetry from the same thread
        // as it will later send feedback
        navigator.native.getTelemetryForEventsMetadataProvider(eventsMetadataProvider)
    }
}

extension TileEndpointConfiguration {
    /// Initializes an object that configures a navigator to obtain routing tiles of the given version from an endpoint,
    /// using the given credentials.
    /// - Parameters:
    ///   - apiConfiguration: ApiConfiguration for accessing road network data.
    ///   - tilesVersion: Routing tile version.
    ///   - minimumDaysToPersistVersion: The minimum age in days that a tile version much reach before a new version can
    /// be requested from the tile endpoint.
    ///   - targetVersion: Routing tile version, which navigator would like to eventually switch to if it becomes
    /// available
    ///   - datasetProfileIdentifier profile setting, used for selecting tiles type for navigation.
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
