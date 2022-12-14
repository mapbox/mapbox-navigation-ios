import MapboxDirections
import MapboxNavigationNative
@testable import MapboxCoreNavigation
@_implementationOnly import MapboxCommon_Private

public final class CoreNavigatorSpy: CoreNavigator {
    public static var shared: CoreNavigatorSpy = .init()

    public static var isSharedInstanceCreated = true
    public static var datasetProfileIdentifier: ProfileIdentifier = .automobile

    public var updateLocationCalled = false
    public var restartNavigatorCalled = false
    public var startUpdatingElectronicHorizonCalled = false
    public var stopUpdatingElectronicHorizonCalled = false
    public var pauseCalled = false
    public var resumeCalled = false
    public var setRoutesCalled = false
    public var setAlternativeRoutesCalled = false
    public var unsetRoutesCalled = false

    public var onUpdateLocation: ((CLLocation) -> Bool)?

    public var passedUuid: UUID?
    public var passedRoute: RouteInterface?
    public var passedLegIndex: UInt32?
    public var passedAlternativeRoutes: [RouteInterface]?
    public var passedLocation: CLLocation?
    public var passedElectronicHorizonOptions: MapboxCoreNavigation.ElectronicHorizonOptions?
    public var passedRoutes: [RouteInterface]?

    public var returnedSetRoutesResult: Result<RoutesCoordinator.RoutesResult, Error>?
    public var returnedSetAlternativeRoutesResult: Result<[RouteAlternative], Error>?

    public var navigatorSpy = NativeNavigatorSpy()
    public var navigator: MapboxNavigationNative.Navigator {
        return navigatorSpy
    }

    public var mostRecentNavigationStatus: NavigationStatus?

    public var tileStore: TileStore = TileStore.__create()

    public var roadGraph = RoadGraph(GraphAccessorSpy())
    public var roadObjectStore = RoadObjectStore(NativeNavigatorSpy().roadObjectStore())
    public var roadObjectMatcher = RoadObjectMatcher(RoadObjectMatcherSpy())

    public var rerouteController: MapboxCoreNavigation.RerouteController = RerouteControllerSpy()

    public func reset() {
        setRoutesCalled = false
        passedRoute = nil
        passedUuid = nil
        passedLegIndex = nil
        passedAlternativeRoutes = nil

        pauseCalled = false
        resumeCalled = false
        restartNavigatorCalled = false

        setAlternativeRoutesCalled = false
        passedRoutes = nil

        unsetRoutesCalled = false
        passedUuid = nil

        updateLocationCalled = false
        passedLocation = nil

        startUpdatingElectronicHorizonCalled = false
        passedElectronicHorizonOptions = nil

        stopUpdatingElectronicHorizonCalled = false
    }

    public func restartNavigator(forcing version: String?) {
        restartNavigatorCalled = true
    }

    public func startUpdatingElectronicHorizon(with options: MapboxCoreNavigation.ElectronicHorizonOptions?) {
        startUpdatingElectronicHorizonCalled = true
        passedElectronicHorizonOptions = options
    }

    public func stopUpdatingElectronicHorizon() {
        stopUpdatingElectronicHorizonCalled = true
    }

    public func setRoutes(_ routesData: RoutesData,
                          uuid: UUID,
                          legIndex: UInt32,
                          completion: @escaping (Result<RoutesCoordinator.RoutesResult, Error>) -> Void) {
        setRoutesCalled = true
        passedRoute = routesData.primaryRoute()
        passedUuid = uuid
        passedLegIndex = legIndex
        passedAlternativeRoutes = routesData.alternativeRoutes().map { $0.route }
        completion(returnedSetRoutesResult ?? .success((mainRouteInfo: nil, alternativeRoutes: [])))
    }

    public func setAlternativeRoutes(with routes: [RouteInterface], completion: @escaping (Result<[RouteAlternative], Error>) -> Void) {
        setAlternativeRoutesCalled = true
        passedRoutes = routes
        completion(returnedSetAlternativeRoutesResult ?? .success([]))
    }

    public func unsetRoutes(uuid: UUID, completion: @escaping (Result<MapboxCoreNavigation.RoutesCoordinator.RoutesResult, Error>) -> Void) {
        unsetRoutesCalled = true
        passedUuid = uuid
    }

    public func updateLocation(_ location: CLLocation, completion: @escaping (Bool) -> Void) {
        updateLocationCalled = true
        passedLocation = location
        let result = onUpdateLocation?(location) ?? true
        completion(result)
    }

    public func pause() {
        pauseCalled = true
    }

    public func resume() {
        resumeCalled = true
    }

    public static func reset() {
        shared = CoreNavigatorSpy()
        Self.isSharedInstanceCreated = true
        Self.datasetProfileIdentifier = .automobile
    }

    public init() {}

}

class GraphAccessorSpy: GraphAccessor {
    init() {
        let configHandle = NativeHandlersFactory.configHandle()
        let tileConfig = TilesConfig(tilesPath: "tileStorePath",
                                     tileStore: nil,
                                     inMemoryTileCache: nil,
                                     onDiskTileCache: nil,
                                     mapMatchingSpatialCache: nil,
                                     threadsCount: nil,
                                     endpointConfig: nil)
        let cache = CacheFactory.build(for: tileConfig, config: configHandle, historyRecorder: nil)
        super.init(cache: cache)
    }
}

class RoadObjectMatcherSpy: MapboxNavigationNative.RoadObjectMatcher {
    init() {
        let configHandle = NativeHandlersFactory.configHandle()
        let tileConfig = TilesConfig(tilesPath: "tileStorePath",
                                     tileStore: nil,
                                     inMemoryTileCache: nil,
                                     onDiskTileCache: nil,
                                     mapMatchingSpatialCache: nil,
                                     threadsCount: nil,
                                     endpointConfig: nil)
        let cache = CacheFactory.build(for: tileConfig, config: configHandle, historyRecorder: nil)
        super.init(cache: cache)
    }
}
