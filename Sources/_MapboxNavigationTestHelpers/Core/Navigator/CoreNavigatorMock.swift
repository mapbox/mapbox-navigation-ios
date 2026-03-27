import _MapboxNavigationHelpers
import Foundation
import MapboxMaps
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private

public final class CoreNavigatorMock: CoreNavigator {
    public var rawLocation: UnfairLocked<CLLocation?> = .init(nil)

    public var mostRecentNavigationStatus: NavigationStatus?

    @MainActor
    public var navigationStatus: NavigationStatus

    public var tileStore: TileStore

    var tilesManager: TilesManagerHandle

    public var roadGraph: RoadGraph

    public var roadObjectStore: RoadObjectStore

    public var rerouteController: RerouteController?

    public var passedElectronicHorizonConfig: ElectronicHorizonConfig?

    @MainActor
    public init() {
        let configHandle = ConfigHandle.mock()
        self.tilesManager = TilesManagerHandle.build(
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
        let nativeNavigator = MapboxNavigationNative_Private.Navigator(
            config: configHandle,
            tilesManager: tilesManager,
            historyRecorder: nil
        )
        self.rerouteController = .mock(navigator: .mock())
        self.roadObjectStore = .init(nativeNavigator.roadObjectsStore())
        self.roadGraph = .init(MapboxNavigationNative_Private.GraphAccessor(tilesManager: tilesManager))
        self.tileStore = .__create(forPath: "")
        self.navigationStatus = .mock(primaryRouteId: nil)
    }

    public func startUpdatingElectronicHorizon(with config: ElectronicHorizonConfig?) {
        passedElectronicHorizonConfig = config
    }

    public var stopUpdatingElectronicHorizonCalled = false
    public func stopUpdatingElectronicHorizon() {
        stopUpdatingElectronicHorizonCalled = true
    }

    var returnedNavigationStatus: @Sendable (any RoutesData, UInt32) async
        -> NavigationStatus = { routesData, legIndex in
            await .mockStartOfNavigation(routesDate: routesData, legIndex: legIndex)
        }

    public var setRoutesCalled = false
    public var passedRoutesData: (any RoutesData)?
    public var passedLegIndex: UInt32?
    public var passedSetReason: SetRoutesReason?
    public var setRoutesResult: Result<RoutesCoordinator.RoutesResult, any Error> = .failure(
        NavigatorErrors
            .UnexpectedNavigationStatus()
    )
    public var unsetRoutesResult: Result<RoutesCoordinator.RoutesResult, any Error> = .success((
        mainRouteInfo: nil,
        alternativeRoutes: []
    ))

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
        if case .success = setRoutesResult {
            let result = setRoutesResult
            let provider = returnedNavigationStatus
            Task { @MainActor in
                self.navigationStatus = await provider(routesData, legIndex)
                completion(result)
            }
        } else {
            completion(setRoutesResult)
        }
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

    var updateRouteLegCalled = false
    var passedUpdatedLegIndex: UInt32?
    var updateRouteLegResult = true

    public func updateRouteLeg(to index: UInt32, completion: @escaping @Sendable (Bool) -> Void) {
        updateRouteLegCalled = true
        passedUpdatedLegIndex = index

        Task { @MainActor in
            if updateRouteLegResult {
                let status = if let passedRoutesData {
                    await returnedNavigationStatus(passedRoutesData, index)
                } else {
                    NavigationStatus.mock(legIndex: index)
                }

                self.navigationStatus = status
            }
            completion(updateRouteLegResult)
        }
    }

    public var unsetRoutesCalled = false
    public var passedUuid: UUID?
    public func unsetRoutes(
        uuid: UUID,
        completion: @escaping @Sendable (Result<RoutesCoordinator.RoutesResult, any Error>) -> Void
    ) {
        unsetRoutesCalled = true
        passedUuid = uuid
        navigationStatus = .mock(primaryRouteId: nil)
        completion(unsetRoutesResult)
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
