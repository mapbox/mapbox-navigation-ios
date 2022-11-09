import MapboxDirections
import MapboxNavigationNative
@testable import MapboxCoreNavigation
@_implementationOnly import MapboxCommon_Private

public final class NavigatorSpy: NavigatorProtocol {
    public static var shared: NavigatorSpy = NavigatorSpy()

    public static var datasetProfileIdentifier: ProfileIdentifier = .automobile

    public var updateLocationCalled = false
    public var restartNavigatorCalled = false
    public var startUpdatingElectronicHorizonCalled = false
    public var stopUpdatingElectronicHorizonCalled = false
    public var pauseCalled = false

    public var onUpdateLocation: ((CLLocation) -> Bool)?

    public var location: CLLocation? = nil
    public var electronicHorizonOptions: MapboxCoreNavigation.ElectronicHorizonOptions? = nil

    public var navigatorSpy = NativeNavigatorSpy()
    public var navigator: MapboxNavigationNative.Navigator {
        return navigatorSpy
    }

    public var mostRecentNavigationStatus: NavigationStatus? = nil

    public var tileStore: TileStore = TileStore.__create()

    public var roadGraph = RoadGraph(GraphAccessorSpy())
    public var roadObjectStore = RoadObjectStore(NativeNavigatorSpy().roadObjectStore())
    public var roadObjectMatcher = RoadObjectMatcher(RoadObjectMatcherSpy())

    public var rerouteController: MapboxCoreNavigation.RerouteController = RerouteControllerSpy()

    public func restartNavigator(forcing version: String?) {
        restartNavigatorCalled = true
    }

    public func startUpdatingElectronicHorizon(with options: MapboxCoreNavigation.ElectronicHorizonOptions?) {
        startUpdatingElectronicHorizonCalled = true
        electronicHorizonOptions = options
    }

    public func stopUpdatingElectronicHorizon() {
        stopUpdatingElectronicHorizonCalled = true
    }

    public func setRoutes(_ route: RouteInterface, uuid: UUID, legIndex: UInt32, alternativeRoutes: [RouteInterface], completion: @escaping (Result<MapboxCoreNavigation.RoutesCoordinator.RoutesResult, Error>) -> Void) {

    }

    public func setAlternativeRoutes(with routes: [RouteInterface], completion: @escaping (Result<[RouteAlternative], Error>) -> Void) {

    }

    public func unsetRoutes(uuid: UUID, completion: @escaping (Result<MapboxCoreNavigation.RoutesCoordinator.RoutesResult, Error>) -> Void) {

    }

    public func updateLocation(_ location: CLLocation, completion: @escaping (Bool) -> Void) {
        updateLocationCalled = true
        self.location = location
        let result = onUpdateLocation?(location) ?? true
        completion(result)
    }

    public func pause() {
        pauseCalled = true
    }

    public static func reset() {
        shared = NavigatorSpy()
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
