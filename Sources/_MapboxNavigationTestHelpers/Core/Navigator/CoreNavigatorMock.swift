import Foundation
import MapboxMaps
@testable import MapboxNavigationCore
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

public final class CoreNavigatorMock: CoreNavigator {
    public var rawLocation: CLLocation?

    public var mostRecentNavigationStatus: NavigationStatus?

    public var tileStore: TileStore

    var cacheHandle: CacheHandle

    public var roadGraph: RoadGraph

    public var roadObjectStore: RoadObjectStore

    public var roadObjectMatcher: MapboxNavigationCore.RoadObjectMatcher

    public var rerouteController: RerouteController?

    public var passedElectronicHorizonConfig: ElectronicHorizonConfig?

    @MainActor
    public init() {
        let configHandle = ConfigHandle.mock()
        self.cacheHandle = CacheFactory.build(
            for: .init(
                tilesPath: "",
                tileStore: nil,
                inMemoryTileCache: nil,
                onDiskTileCache: nil,
                endpointConfig: nil,
                hdEndpointConfig: nil
            ),
            config: configHandle,
            historyRecorder: nil,
            frameworkTypeForSKU: .CF
        )
        let nativeNavigator = MapboxNavigationNative.Navigator(
            config: configHandle,
            cache: cacheHandle,
            historyRecorder: nil
        )
        self.rerouteController = .mock(navigator: .mock())
        self.roadObjectMatcher = .init(MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle))
        self.roadObjectStore = .init(nativeNavigator.roadObjectStore())
        self.roadGraph = .init(MapboxNavigationNative.GraphAccessor(cache: cacheHandle))
        self.tileStore = .__create(forPath: "")
    }

    public func startUpdatingElectronicHorizon(with config: ElectronicHorizonConfig?) {
        passedElectronicHorizonConfig = config
    }

    public var stopUpdatingElectronicHorizonCalled = false
    public func stopUpdatingElectronicHorizon() {
        stopUpdatingElectronicHorizonCalled = true
    }

    public var setRoutesCalled = false
    public var passedRoutesData: (any RoutesData)?
    public var passedLegIndex: UInt32?
    public var passedSetReason: SetRoutesReason?
    public var setRoutesResult: Result<RoutesCoordinator.RoutesResult, any Error> = .failure(
        NavigatorErrors
            .UnexpectedNavigationStatus()
    )
    public func setRoutes(
        _ routesData: any RoutesData,
        uuid: UUID,
        legIndex: UInt32,
        reason: SetRoutesReason,
        completion: @escaping @Sendable (Result<RoutesCoordinator.RoutesResult, any Error>) -> Void
    ) {
        setRoutesCalled = true
        passedRoutesData = routesData
        passedUuid = uuid
        passedLegIndex = legIndex
        passedSetReason = reason
        completion(setRoutesResult)
    }

    public var setAlternativeRoutesCalled = false
    public var setAlternativeRoutesResult: Result<[RouteAlternative], any Error> = .failure(
        NavigatorErrors
            .UnexpectedNavigationStatus()
    )
    public func setAlternativeRoutes(
        with routes: [any RouteInterface],
        completion: @escaping @Sendable (Result<[RouteAlternative], any Error>) -> Void
    ) {
        setAlternativeRoutesCalled = true
        completion(setAlternativeRoutesResult)
    }

    public var updateRouteLegCalled = false
    public func updateRouteLeg(to index: UInt32, completion: @escaping @Sendable (Bool) -> Void) {
        updateRouteLegCalled = true
    }

    public var unsetRoutesCalled = false
    public var passedUuid: UUID?
    public func unsetRoutes(
        uuid: UUID,
        completion: @escaping @Sendable (Result<RoutesCoordinator.RoutesResult, any Error>) -> Void
    ) {
        unsetRoutesCalled = true
        passedUuid = uuid
    }

    public func unsetRoutes(uuid: UUID) async throws {
        unsetRoutesCalled = true
        passedUuid = uuid
    }

    public var passedUpdateLocation: CLLocation?
    public func updateLocation(_ location: CLLocation, completion: @escaping @Sendable (Bool) -> Void) {
        passedUpdateLocation = location
        completion(true)
    }

    public var resumeCalled = false
    public func resume() {
        resumeCalled = true
    }

    public var pauseCalled = false
    public func pause() {
        pauseCalled = true
    }
}
