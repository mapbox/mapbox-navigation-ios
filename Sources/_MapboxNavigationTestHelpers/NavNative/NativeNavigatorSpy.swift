@_implementationOnly import MapboxCommon_Private
@testable import MapboxNavigationCore
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

extension NavigationNativeNavigator {
    @MainActor
    public static func mock() -> Self {
        .init(navigator: NativeNavigatorSpy(), locale: .current)
    }
}

public class NativeNavigatorSpy: MapboxNavigationNative.Navigator {
    public var passedTileStore: TileStore?
    public var passedDescriptors: [TilesetDescriptor]?
    public var passedCacheOptions: PredictiveCacheControllerOptions?
    public var passedRerouteController: RerouteControllerInterface?
    public var passedLeg: UInt32? = nil
    public var returnedChangeLegResult = true

    public var passedNavigationTrackerOptions: PredictiveLocationTrackerOptions?
    public var passedDescriptorsTrackerOptions: PredictiveLocationTrackerOptions?
    public var passedDatasetTrackerOptions: PredictiveLocationTrackerOptions?
    public var passedRemovedRerouteObserver: RerouteObserver?

    public var rerouteController: RerouteControllerInterface? = NativeRerouteControllerSpy()
    public var rerouteDetector: RerouteDetectorInterface? = RerouteDetectorSpy()

    public var startNavigationSessionCalled = false
    public var stopNavigationSessionCalled = false

    public init() {
        let factory = NativeHandlersFactory(
            tileStorePath: "",
            apiConfiguration: .mock(),
            tilesVersion: "",
            datasetProfileIdentifier: .automobile,
            liveIncidentsOptions: nil,
            navigatorPredictionInterval: nil,
            utilizeSensorData: true,
            historyDirectoryURL: nil,
            initialManeuverAvoidanceRadius: 8,
            locale: .current
        )

        super.init(
            config: factory.configHandle(),
            cache: factory.cacheHandle,
            historyRecorder: nil
        )
    }

    override public func createPredictiveCacheController(for options: PredictiveLocationTrackerOptions)
    -> PredictiveCacheController {
        passedNavigationTrackerOptions = options
        return super.createPredictiveCacheController(for: options)
    }

    override public func createPredictiveCacheController(
        for tileStore: TileStore,
        descriptors: [TilesetDescriptor],
        locationTrackerOptions: PredictiveLocationTrackerOptions
    )
    -> PredictiveCacheController {
        passedTileStore = tileStore
        passedDescriptors = descriptors
        passedDescriptorsTrackerOptions = locationTrackerOptions
        return super.createPredictiveCacheController(for: locationTrackerOptions)
    }

    override public func createPredictiveCacheController(
        for tileStore: TileStore,
        cacheOptions: PredictiveCacheControllerOptions,
        locationTrackerOptions: PredictiveLocationTrackerOptions
    )
    -> PredictiveCacheController {
        passedTileStore = tileStore
        passedCacheOptions = cacheOptions
        passedDatasetTrackerOptions = locationTrackerOptions
        return super.createPredictiveCacheController(for: locationTrackerOptions)
    }

    override public func changeLeg(forLeg leg: UInt32, callback: @escaping ChangeLegCallback) {
        passedLeg = leg
        callback(returnedChangeLegResult)
    }

    override public func removeRerouteObserver(for observer: RerouteObserver) {
        passedRemovedRerouteObserver = observer
    }

    @_implementationOnly
    override public func setRerouteControllerForController(
        _ controller: RerouteControllerInterface
    ) {
        passedRerouteController = controller
    }

    @_implementationOnly
    override public func getRerouteController() -> RerouteControllerInterface? {
        rerouteController
    }

    @_implementationOnly
    override public func getRerouteDetector() -> RerouteDetectorInterface? {
        rerouteDetector
    }

    override public func startNavigationSession() {
        startNavigationSessionCalled = true
    }

    override public func stopNavigationSession() {
        stopNavigationSessionCalled = true
    }
}
