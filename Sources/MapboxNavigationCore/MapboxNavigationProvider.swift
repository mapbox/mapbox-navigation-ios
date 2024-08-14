import _MapboxNavigationHelpers
import Foundation
import MapboxCommon
import MapboxCommon_Private
import MapboxNavigationNative
import MapboxNavigationNative_Private

public final class MapboxNavigationProvider {
    let multiplexLocationClient: MultiplexLocationClient

    public var skuTokenProvider: SkuTokenProvider {
        billingHandler.skuTokenProvider()
    }

    public var predictiveCacheManager: PredictiveCacheManager? {
        coreConfig.predictiveCacheConfig.map {
            PredictiveCacheManager(
                predictiveCacheOptions: $0,
                tileStore: coreConfig.tilestoreConfig.navigatorLocation.tileStore
            )
        }
    }

    private var _sharedRouteVoiceController: RouteVoiceController?
    @MainActor
    public var routeVoiceController: RouteVoiceController {
        if let _sharedRouteVoiceController {
            return _sharedRouteVoiceController
        } else {
            let routeVoiceController = RouteVoiceController(
                routeProgressing: navigation().routeProgress,
                rerouteStarted: navigation().rerouting
                    .filter { $0.event is ReroutingStatus.Events.FetchingRoute }
                    .map { _ in }
                    .eraseToAnyPublisher(),
                fasterRouteSet: navigation().fasterRoutes
                    .filter { $0.event is FasterRoutesStatus.Events.Applied }
                    .map { _ in }
                    .eraseToAnyPublisher(),
                speechSynthesizer: coreConfig.ttsConfig.speechSynthesizer(
                    with: coreConfig.locale,
                    apiConfiguration: coreConfig.credentials.speech,
                    skuTokenProvider: skuTokenProvider
                )
            )
            _sharedRouteVoiceController = routeVoiceController
            return routeVoiceController
        }
    }

    private let _coreConfig: UnfairLocked<CoreConfig>

    public var coreConfig: CoreConfig {
        _coreConfig.read()
    }

    /// Creates a new ``MapboxNavigationProvider``.
    ///
    /// You should never instantiate multiple instances of ``MapboxNavigationProvider`` simultaneously.
    /// - parameter coreConfig: A configuration for the SDK. It is recommended not modify the configuration during
    /// operation, but it is still possible via ``MapboxNavigationProvider/apply(coreConfig:)``.
    public init(coreConfig: CoreConfig) {
        Self.checkInstanceIsUnique()
        self._coreConfig = .init(coreConfig)
        self.multiplexLocationClient = MultiplexLocationClient(source: coreConfig.locationSource)
        apply(coreConfig: coreConfig)
        SdkInfoRegistryFactory.getInstance().registerSdkInformation(forInfo: SdkInfo.navigationCore.native)
        MovementMonitorFactory.setUserDefinedForCustom(movementMonitor)
    }

    /// Updates the SDK configuration.
    ///
    /// It is not recommended to do so due to some updates may be propagated incorrectly.
    /// - Parameter coreConfig: The configuration for the SDK.
    public func apply(coreConfig: CoreConfig) {
        _coreConfig.update(coreConfig)

        let logLevel = NSNumber(value: coreConfig.logLevel.rawValue)
        LogConfiguration.setLoggingLevelForCategory("nav-native", upTo: logLevel)
        LogConfiguration.setLoggingLevelForUpTo(logLevel)
        eventsMetadataProvider.userInfo = coreConfig.telemetryAppMetadata?.configuration

        MapboxOptions.accessToken = coreConfig.credentials.map.accessToken
        let copilotEnabled = coreConfig.copilotEnabled
        let locationSource = coreConfig.locationSource
        let locationClient = multiplexLocationClient
        let ttsConfig = coreConfig.ttsConfig
        let locale = coreConfig.locale
        let speechApiConfiguration = coreConfig.credentials.speech
        let skuTokenProvider = skuTokenProvider

        nativeHandlersFactory.locale = coreConfig.locale
        Task { @MainActor [_copilot, _sharedRouteVoiceController] in
            await _copilot?.setActive(copilotEnabled)
            if locationClient.isInitialized {
                locationClient.setLocationSource(locationSource)
            }
            _sharedRouteVoiceController?.speechSynthesizer = ttsConfig.speechSynthesizer(
                with: locale,
                apiConfiguration: speechApiConfiguration,
                skuTokenProvider: skuTokenProvider
            )
        }
    }

    /// Provides an entry point for interacting with the Mapbox Navigation SDK.
    ///
    /// This instance is shared.
    @MainActor
    public var mapboxNavigation: MapboxNavigation {
        self
    }

    /// Gets TilesetDescriptor that corresponds to the latest available version of routing tiles.
    ///
    /// It is intended to be used when creating off-line tile packs.
    public func getLatestNavigationTilesetDescriptor() -> TilesetDescriptor {
        TilesetDescriptorFactory.getLatestForCache(nativeHandlersFactory.cacheHandle)
    }

    // MARK: - Instance Lifecycle control

    private static let hasInstance: NSLocked<Bool> = .init(false)

    private static func checkInstanceIsUnique() {
        hasInstance.mutate { hasInstance in
            if hasInstance {
                Log.fault(
                    "[BUG] Two simultaneous active navigation cores. Profile the app and make sure that MapboxNavigationProvider is allocated only once.",
                    category: .navigation
                )
                preconditionFailure("MapboxNavigationProvider was instantiated twice.")
            }
            hasInstance = true
        }
    }

    private func unregisterUniqueInstance() {
        Self.hasInstance.update(false)
    }

    deinit {
        unregisterUniqueInstance()
    }

    // MARK: - Internal members

    private weak var _sharedNavigator: MapboxNavigator?
    @MainActor
    func navigator() -> MapboxNavigator {
        if let sharedNavigator = _sharedNavigator {
            return sharedNavigator
        } else {
            let coreNavigator: CoreNavigator = NativeNavigator(
                with: .init(
                    credentials: coreConfig.credentials.navigation,
                    nativeHandlersFactory: nativeHandlersFactory,
                    routingConfig: coreConfig.routingConfig,
                    predictiveCacheManager: predictiveCacheManager
                )
            )
            let fasterRouteController = coreConfig.routingConfig.fasterRouteDetectionConfig.map {
                return $0.customFasterRouteProvider ?? FasterRouteController(
                    configuration: .init(
                        settings: $0,
                        initialManeuverAvoidanceRadius: coreConfig.routingConfig.initialManeuverAvoidanceRadius,
                        routingProvider: routingProvider()
                    )
                )
            }

            let newNavigator = MapboxNavigator(
                configuration: .init(
                    navigator: coreNavigator,
                    routeParserType: RouteParser.self,
                    locationClient: multiplexLocationClient.locationClient,
                    alternativesAcceptionPolicy: coreConfig.routingConfig.alternativeRoutesDetectionConfig?
                        .acceptionPolicy,
                    billingHandler: billingHandler,
                    multilegAdvancing: coreConfig.multilegAdvancing,
                    prefersOnlineRoute: coreConfig.routingConfig.prefersOnlineRoute,
                    disableBackgroundTrackingLocation: coreConfig.disableBackgroundTrackingLocation,
                    fasterRouteController: fasterRouteController,
                    electronicHorizonConfig: coreConfig.electronicHorizonConfig,
                    congestionConfig: coreConfig.congestionConfig,
                    movementMonitor: movementMonitor
                )
            )
            _sharedNavigator = newNavigator
            _ = eventsManager()

            multiplexLocationClient.subscribeToNavigatorUpdates(
                newNavigator,
                source: coreConfig.locationSource
            )

            // Telemetry needs to be created for Navigator

            return newNavigator
        }
    }

    private var _billingHandler: UnfairLocked<BillingHandler?> = .init(nil)
    var billingHandler: BillingHandler {
        _billingHandler.mutate { lazyInstance in
            if let lazyInstance {
                return lazyInstance
            } else {
                let newInstance = coreConfig.__customBillingHandler?()
                    ?? BillingHandler.createInstance(with: coreConfig.credentials.navigation.accessToken)
                lazyInstance = newInstance
                return newInstance
            }
        }
    }

    lazy var nativeHandlersFactory: NativeHandlersFactory = .init(
        tileStorePath: coreConfig.tilestoreConfig.navigatorLocation.tileStoreURL?.path ?? "",
        apiConfiguration: coreConfig.credentials.navigation,
        tilesVersion: coreConfig.tilesVersion,
        targetVersion: nil,
        configFactoryType: ConfigFactory.self,
        datasetProfileIdentifier: coreConfig.routeRequestConfig.profileIdentifier,
        routingProviderSource: coreConfig.routingConfig.routingProviderSource.nativeSource,
        liveIncidentsOptions: coreConfig.liveIncidentsConfig,
        navigatorPredictionInterval: coreConfig.navigatorPredictionInterval,
        statusUpdatingSettings: nil,
        utilizeSensorData: coreConfig.utilizeSensorData,
        historyDirectoryURL: coreConfig.historyRecordingConfig?.historyDirectoryURL,
        initialManeuverAvoidanceRadius: coreConfig.routingConfig.initialManeuverAvoidanceRadius,
        locale: coreConfig.locale
    )

    private lazy var _historyRecorder: HistoryRecording? = {
        guard let historyDirectoryURL = coreConfig.historyRecordingConfig?.historyDirectoryURL else {
            return nil
        }
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: historyDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Log.error(
                "Failed to create history saving directory at '\(historyDirectoryURL)' due to error: \(error)",
                category: .settings
            )
            return nil
        }
        return nativeHandlersFactory.historyRecorderHandle.map {
            HistoryRecorder(handle: $0)
        }
    }()

    private lazy var _copilot: CopilotService? = {
        guard let _historyRecorder else { return nil }
        let version = onMainQueueSync { nativeHandlersFactory.navigator.native.version() }
        return .init(
            accessToken: coreConfig.credentials.navigation.accessToken,
            navNativeVersion: version,
            historyRecording: _historyRecorder,
            isActive: coreConfig.copilotEnabled,
            log: { logOutput in
                Log.debug(
                    "\(logOutput)",
                    category: .copilot
                )
            }
        )
    }()

    var eventsMetadataProvider: EventsMetadataProvider {
        onMainQueueSync {
            let eventsMetadataProvider = EventsMetadataProvider(
                appState: EventAppState(),
                screen: .main,
                device: .current
            )
            eventsMetadataProvider.userInfo = coreConfig.telemetryAppMetadata?.configuration
            return eventsMetadataProvider
        }
    }

    // Need to store the metadata provider and NN Telemetry
    private var _sharedEventsManager: UnfairLocked<NavigationEventsManager?> = .init(nil)

    var movementMonitor: NavigationMovementMonitor {
        _sharedMovementMonitor.mutate { _sharedMovementMonitor in
            if let _sharedMovementMonitor {
                return _sharedMovementMonitor
            }
            let movementMonitor = NavigationMovementMonitor()
            _sharedMovementMonitor = movementMonitor
            return movementMonitor
        }
    }

    private var _sharedMovementMonitor: UnfairLocked<NavigationMovementMonitor?> = .init(nil)
}

// MARK: - MapboxNavigation implementation

extension MapboxNavigationProvider: MapboxNavigation {
    public func routingProvider() -> RoutingProvider {
        if let customProvider = coreConfig.__customRoutingProvider {
            return customProvider()
        }
        return MapboxRoutingProvider(
            with: .init(
                source: coreConfig.routingConfig.routingProviderSource,
                nativeHandlersFactory: nativeHandlersFactory,
                credentials: .init(coreConfig.credentials.navigation)
            )
        )
    }

    public func tripSession() -> SessionController {
        navigator()
    }

    public func electronicHorizon() -> ElectronicHorizonController {
        navigator()
    }

    public func navigation() -> NavigationController {
        navigator()
    }

    public func eventsManager() -> NavigationEventsManager {
        let telemetry = nativeHandlersFactory
            .telemetry(eventsMetadataProvider: eventsMetadataProvider)
        return _sharedEventsManager.mutate { _sharedEventsManager in
            if let _sharedEventsManager {
                return _sharedEventsManager
            }
            let eventsMetadataProvider = eventsMetadataProvider
            let eventsManager = coreConfig.__customEventsManager?() ?? NavigationEventsManager(
                eventsMetadataProvider: eventsMetadataProvider,
                telemetry: telemetry
            )
            _sharedEventsManager = eventsManager
            return eventsManager
        }
    }

    public func historyRecorder() -> HistoryRecording? {
        _historyRecorder
    }

    public func copilot() -> CopilotService? {
        _copilot
    }
}

extension TTSConfig {
    @MainActor
    fileprivate func speechSynthesizer(
        with locale: Locale,
        apiConfiguration: ApiConfiguration,
        skuTokenProvider: SkuTokenProvider
    ) -> SpeechSynthesizing {
        let speechSynthesizer = switch self {
        case .default:
            MultiplexedSpeechSynthesizer(
                mapboxSpeechApiConfiguration: apiConfiguration,
                skuTokenProvider: skuTokenProvider.skuToken
            )
        case .localOnly:
            MultiplexedSpeechSynthesizer(speechSynthesizers: [SystemSpeechSynthesizer()])
        case .custom(let speechSynthesizer):
            speechSynthesizer
        }
        speechSynthesizer.locale = locale
        return speechSynthesizer
    }
}
