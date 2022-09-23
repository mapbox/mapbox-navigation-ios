import MapboxNavigationNative
import MapboxDirections
@_implementationOnly import MapboxCommon_Private

class Navigator {
    /**
     Tiles version string. If not specified explicitly - will be automatically resolved
     to the latest version.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect.
     */
    static var tilesVersion: String = ""
    
    private(set) var navigator: MapboxNavigationNative.Navigator
    
    private(set) var cacheHandle: CacheHandle
    
    var mostRecentNavigationStatus: NavigationStatus? {
        navigatorStatusObserver?.mostRecentNavigationStatus
    }
    
    private(set) var tileStore: TileStore
    
    /**
     Current Navigator status in terms of tile versioning.
     */
    var tileVersionState: NavigatorFallbackVersionsObserver.TileVersionState {
        navigatorFallbackVersionsObserver?.tileVersionState ?? .nominal
    }

    private lazy var routeCoordinator: RoutesCoordinator = {
        .init(routesSetupHandler: { [weak self] route, legIndex, alternativeRoutes, completion in
            var routesParams: SetRoutesParams? = nil
            if let route = route {
                routesParams = SetRoutesParams(primaryRoute: route,
                                               legIndex: legIndex,
                                               alternativeRoutes: alternativeRoutes)
            }
            
            self?.navigator.setRoutesFor(routesParams) { [weak self] result in
                if result.isValue(),
                   let routesResult = result.value {
                    Log.info("Navigator has been updated, including \(routesResult.alternatives.count) alternatives.", category: .navigation)
                    completion(.success((route?.getRouteInfo(), routesResult.alternatives)))
                }
                else if result.isError() {
                    let reason = (result.error as String?) ?? ""
                    Log.error("Failed to update navigator with reason: \(reason)", category: .navigation)
                    completion(.failure(NavigatorError.failedToUpdateRoutes(reason: reason)))
                }
                else {
                    assertionFailure("Invalid Expected value: \(result)")
                    completion(.failure(NavigatorError.failedToUpdateRoutes(reason: "Unexpected internal response")))
                }
            }
        }, alternativeRoutesSetupHandler: {[weak self] routes, completion in
            self?.navigator.setAlternativeRoutesForRoutes(routes, callback: { result in
                if result.isValue(),
                   let alternatives = result.value as? [RouteAlternative] {
                    Log.info("Navigator alternative routes has been updated (\(alternatives.count) alternatives set).",
                             category: .navigation)
                    completion(.success(alternatives))
                } else {
                    let reason = (result.error as String?) ?? ""
                    Log.error("Failed to update navigator alternative routes with reason: \(reason)",
                              category: .navigation)
                    completion(.failure(NavigatorError.failedToUpdateAlternativeRoutes(reason: reason)))
                }
            })
        })
    }()
    
    private(set) var rerouteController: RerouteController
    
    /**
     Provides a new or an existing `MapboxCoreNavigation.Navigator` instance. Upon first initialization will trigger creation of `MapboxNavigationNative.Navigator` and `HistoryRecorderHandle` instances,
     satisfying provided configuration (`tilesVersion` and `NavigationSettings`).
     */
    static var shared: Navigator {
        guard let navigator = _navigator else {
            let navigator = Navigator()
            _navigator = navigator
            return navigator
        }
        return navigator
    }

    /// `True` when `Navigator.shared` requested at least once.
    static var isSharedInstanceCreated: Bool {
        _navigator != nil
    }
    
    private static weak var _navigator: Navigator?
    // Used in tests to recreate the navigator
    static func _recreateNavigator() { _navigator = nil }
    
    /**
     Profile setting, used for selecting tiles type for navigation.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect. Defaults to `automobileAvoidingTraffic`.
     */
    static var datasetProfileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic
    
    /**
     Restrict direct initializer access.
     */
    private init() {
        let tileStorePath = NavigationSettings.shared.tileStoreConfiguration.navigatorLocation.tileStoreURL?.path
        let factory = NativeHandlersFactory(tileStorePath: tileStorePath ?? "",
                                            credentials: NavigationSettings.shared.directions.credentials,
                                            tilesVersion: Self.tilesVersion,
                                            datasetProfileIdentifier: Self.datasetProfileIdentifier,
                                            routingProviderSource: NavigationSettings.shared.routingProviderSource.nativeSource)
        tileStore = factory.tileStore
        cacheHandle = factory.cacheHandle
        roadGraph = factory.roadGraph
        navigator = factory.navigator
        roadObjectStore = RoadObjectStore(navigator.roadObjectStore())
        roadObjectMatcher = RoadObjectMatcher(MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle))
        rerouteController = RerouteController(navigator, config: NativeHandlersFactory.configHandle())
        
        subscribeNavigator()
        setupAlternativesControllerIfNeeded()
    }

    /**
     Destroys and creates new instance of Navigator together with other related entities.
     
     Typically, this method is used to restart a Navigator with a specific Version during switching to offline or online modes.
     - parameter version: String representing a tile version name. `nil` value means "latest". Specifying exact version also enables `fallback` mode which will passively monitor newer version available and will notify `tileVersionState` if found.
     */
    func restartNavigator(forcing version: String? = nil) {
        unsubscribeNavigator()
        navigator.shutdown()
        
        let factory = NativeHandlersFactory(tileStorePath: NavigationSettings.shared.tileStoreConfiguration.navigatorLocation.tileStoreURL?.path ?? "",
                                            credentials: NavigationSettings.shared.directions.credentials,
                                            tilesVersion: version ?? Self.tilesVersion,
                                            targetVersion: version.map { _ in Self.tilesVersion },
                                            datasetProfileIdentifier: Self.datasetProfileIdentifier,
                                            routingProviderSource: NavigationSettings.shared.routingProviderSource.nativeSource)
        tileStore = factory.tileStore
        cacheHandle = factory.cacheHandle
        roadGraph = factory.roadGraph
        navigator = factory.navigator
        
        roadObjectStore.native = navigator.roadObjectStore()
        roadObjectMatcher.native = MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle)
        rerouteController = RerouteController(navigator, config: NativeHandlersFactory.configHandle())
        
        subscribeNavigator()
        setupAlternativesControllerIfNeeded()
    }
    
    private weak var navigatorStatusObserver: NavigatorStatusObserver?
    private weak var navigatorFallbackVersionsObserver: NavigatorFallbackVersionsObserver?
    private weak var navigatorElectronicHorizonObserver: NavigatorElectronicHorizonObserver?
    private weak var navigatorAlternativesObserver: NavigatorRouteAlternativesObserver?

    private func setupAlternativesControllerIfNeeded() {
        guard let strategy = NavigationSettings.shared.alternativeRouteDetectionStrategy else { return }
        
        var refreshOnEmpty = false
        var refreshInterval: TimeInterval = 180
        switch strategy.refreshesWhenNoAvailableAlternatives {
        case .noPeriodicRefresh:
            refreshOnEmpty = false
        case .refreshesPeriodically(let interval):
            refreshOnEmpty = true
            refreshInterval = interval
        }

        let controller = navigator.getRouteAlternativesController()
        controller.enableOnEmptyAlternativesRequest(forEnable: refreshOnEmpty)
        controller.enableRequestAfterFork(forEnable: strategy.refreshesAfterPassingDeviation)
        
        let options = RouteAlternativesOptions(requestIntervalSeconds: refreshInterval,
                                               minTimeBeforeManeuverSeconds: rerouteController.initialManeuverAvoidanceRadius)
        controller.setRouteAlternativesOptionsFor(options)
    }
    
    private func subscribeNavigator() {
        if isSubscribedToElectronicHorizon {
            startUpdatingElectronicHorizon(with: electronicHorizonOptions)
        }
        
        let statusObserver = NavigatorStatusObserver()
        navigatorStatusObserver = statusObserver
        navigator.addObserver(for: statusObserver)
        
        let versionsObserver = NavigatorFallbackVersionsObserver()
        navigatorFallbackVersionsObserver = versionsObserver
        navigator.setFallbackVersionsObserverFor(versionsObserver)
        
        if NavigationSettings.shared.alternativeRouteDetectionStrategy != nil {
            let alternativesObserver = NavigatorRouteAlternativesObserver()
            navigatorAlternativesObserver = alternativesObserver
            navigator.getRouteAlternativesController().addObserver(for: alternativesObserver)
        } else if let navigatorAlternativesObserver = navigatorAlternativesObserver {
            navigator.getRouteAlternativesController().removeObserver(for: navigatorAlternativesObserver)
            self.navigatorAlternativesObserver = nil
        }
    }
    
    private func unsubscribeNavigator() {
        stopUpdatingElectronicHorizon()
        if let navigatorStatusObserver = navigatorStatusObserver {
            navigator.removeObserver(for: navigatorStatusObserver)
        }
        
        navigator.setFallbackVersionsObserverFor(nil)
        
        if let navigatorAlternativesObserver = navigatorAlternativesObserver {
            navigator.getRouteAlternativesController().removeObserver(for: navigatorAlternativesObserver)
            self.navigatorAlternativesObserver = nil
        }
    }
        
    // MARK: Electronic horizon
    
    private(set) var roadGraph: RoadGraph

    private(set) var roadObjectStore: RoadObjectStore

    private(set) var roadObjectMatcher: RoadObjectMatcher
    
    private var isSubscribedToElectronicHorizon = false
    
    private var electronicHorizonOptions: ElectronicHorizonOptions? {
        didSet {
            let nativeOptions = electronicHorizonOptions.map(MapboxNavigationNative.ElectronicHorizonOptions.init)
            navigator.setElectronicHorizonOptionsFor(nativeOptions)
        }
    }
    
    func startUpdatingElectronicHorizon(with options: ElectronicHorizonOptions?) {
        isSubscribedToElectronicHorizon = true
        
        let observer = NavigatorElectronicHorizonObserver()
        navigatorElectronicHorizonObserver = observer
        navigator.setElectronicHorizonObserverFor(observer)
        electronicHorizonOptions = options
    }
    
    func stopUpdatingElectronicHorizon() {
        isSubscribedToElectronicHorizon = false
        navigator.setElectronicHorizonObserverFor(nil)
        electronicHorizonOptions = nil
    }

    // MARK: - Navigator Updates

    func setRoutes(_ route: RouteInterface, uuid: UUID, legIndex: UInt32, alternativeRoutes: [RouteInterface], completion: @escaping (Result<RoutesCoordinator.RoutesResult, Error>) -> Void) {
        routeCoordinator.beginActiveNavigation(with: route, uuid: uuid, legIndex: legIndex, alternativeRoutes: alternativeRoutes, completion: completion)
    }
    
    func setAlternativeRoutes(with routes: [RouteInterface], completion: @escaping (Result<[RouteAlternative], Error>) -> Void) {
        routeCoordinator.updateAlternativeRoutes(with: routes, completion: completion)
    }
    
    func unsetRoutes(uuid: UUID, completion: @escaping (Result<RoutesCoordinator.RoutesResult, Error>) -> Void) {
        routeCoordinator.endActiveNavigation(with: uuid, completion: completion)
    }

    func updateLocation(_ location: CLLocation, completion: @escaping (Bool) -> Void) {
        navigator.updateLocation(for: FixLocation(location), callback: completion)
    }

    func pause() {
        onMainQueueSync {
            navigator.pause()
        }
    }

    func resume() {
        onMainQueueSync {
            navigator.resume()
        }
    }
    
    deinit {
        unsubscribeNavigator()
    }
}

class NavigatorFallbackVersionsObserver: FallbackVersionsObserver {
    
    private(set) var tileVersionState: TileVersionState = .nominal
    
    enum TileVersionState {
        /// No tiles version switch is required. Navigator has enough tiles for map matching.
        case nominal
        /// Navigator does not have tiles on current version for map matching, but TileStore contains regions with required tiles of a different version
        case shouldFallback([String])
        /// Navigator is in a fallback mode but newer tiles version were successefully downloaded and ready to use.
        case shouldReturnToLatest
    }
    
    func onFallbackVersionsFound(forVersions versions: [String]) {
        DispatchQueue.main.async { [self] in
            switch tileVersionState {
            case .nominal, .shouldReturnToLatest:
                tileVersionState = .shouldFallback(versions)
                guard let fallbackVersion = versions.last else { return }
                
                Navigator.shared.restartNavigator(forcing: fallbackVersion)
                
                let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
                    .tilesVersionKey: fallbackVersion
                ]
                
                NotificationCenter.default.post(name: .navigationDidSwitchToFallbackVersion,
                                                object: nil,
                                                userInfo: userInfo)
            case .shouldFallback:
                break // do nothing
            }
        }
    }

    func onCanReturnToLatest(forVersion version: String) {
        DispatchQueue.main.async { [self] in
            switch tileVersionState {
            case .nominal, .shouldFallback:
                tileVersionState = .shouldReturnToLatest
                Navigator.shared.restartNavigator(forcing: nil)
                
                let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
                    .tilesVersionKey: version
                ]
                
                NotificationCenter.default.post(name: .navigationDidSwitchToTargetVersion,
                                                object: nil,
                                                userInfo: userInfo)
            case .shouldReturnToLatest:
                break // do nothing
            }
        }
    }
}

class NavigatorElectronicHorizonObserver: ElectronicHorizonObserver {
    public func onPositionUpdated(for position: ElectronicHorizonPosition, distances: [MapboxNavigationNative.RoadObjectDistance]) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .positionKey: RoadGraph.Position(position.position()),
            .treeKey: RoadGraph.Edge(position.tree().start),
            .updatesMostProbablePathKey: position.type() == .update,
            .distancesByRoadObjectKey: distances.map(DistancedRoadObject.init),
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

    public func onRoadObjectPassed(for info: RoadObjectPassInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidPassRoadObject, object: nil, userInfo: userInfo)
    }
}

class NavigatorStatusObserver: NavigatorObserver {
    var mostRecentNavigationStatus: NavigationStatus? = nil
    
    func onStatus(for origin: NavigationStatusOrigin, status: NavigationStatus) {
        assert(Thread.isMainThread)

        let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
            .originKey: origin,
            .statusKey: status,
        ]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
        
        mostRecentNavigationStatus = status
    }
}

class NavigatorRouteAlternativesObserver: RouteAlternativesObserver {

    func onRouteAlternativesChanged(for routeAlternatives: [RouteAlternative], removed: [RouteAlternative]) {
        let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
            .alternativesListKey: routeAlternatives,
            .removedAlternativesKey: removed,
        ]
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)
    }

    public func onError(forMessage message: String) {
        let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
            .messageKey: message,
        ]
        NotificationCenter.default.post(name: .navigatorDidFailToChangeAlternativeRoutes, object: nil, userInfo: userInfo)
    }
    
    func onOnlinePrimaryRouteAvailable(forOnlinePrimaryRoute onlinePrimaryRoute: RouteInterface) {
        let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
            .coincideOnlineRouteKey: onlinePrimaryRoute,
        ]
        NotificationCenter.default.post(name: .navigatorWantsSwitchToCoincideOnlineRoute, object: nil, userInfo: userInfo)
    }
}

enum NavigatorError: Swift.Error {
    case failedToUpdateRoutes(reason: String)
    case failedToUpdateAlternativeRoutes(reason: String)
}
