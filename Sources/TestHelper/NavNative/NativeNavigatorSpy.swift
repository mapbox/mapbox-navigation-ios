import MapboxNavigationNative
@_implementationOnly import MapboxCommon_Private
@_implementationOnly import MapboxNavigationNative_Private
@testable import MapboxCoreNavigation

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

    public var rerouteController: RerouteControllerInterface!
    public var rerouteDetector: RerouteDetectorInterface!

    public init() {
        let factory = NativeHandlersFactory(tileStorePath: "", credentials: DirectionsSpy.shared.credentials)
        super.init(config: NativeHandlersFactory.configHandle(),
                   cache: factory.cacheHandle,
                   historyRecorder: nil,
                   router: nil)
    }
    
    public override func createPredictiveCacheController(for options: PredictiveLocationTrackerOptions) -> PredictiveCacheController {
        passedNavigationTrackerOptions = options
        return super.createPredictiveCacheController(for: options)
    }

    public override func createPredictiveCacheController(for tileStore: TileStore,
                                                         descriptors: [TilesetDescriptor],
                                                         locationTrackerOptions: PredictiveLocationTrackerOptions) -> PredictiveCacheController {
        passedTileStore = tileStore
        passedDescriptors = descriptors
        passedDescriptorsTrackerOptions = locationTrackerOptions
        return super.createPredictiveCacheController(for: locationTrackerOptions)
    }
    
    public override func createPredictiveCacheController(for tileStore: TileStore,
                                                         cacheOptions: PredictiveCacheControllerOptions,
                                                         locationTrackerOptions: PredictiveLocationTrackerOptions) -> PredictiveCacheController {
        passedTileStore = tileStore
        passedCacheOptions = cacheOptions
        passedDatasetTrackerOptions = locationTrackerOptions
        return super.createPredictiveCacheController(for: locationTrackerOptions)
    }

    public override func changeLeg(forLeg leg: UInt32, callback: @escaping ChangeLegCallback) {
        passedLeg = leg
        callback(returnedChangeLegResult)
    }

    @_implementationOnly public override func setRerouteControllerForController(_ controller: RerouteControllerInterface) {
        passedRerouteController = controller
    }

    @_implementationOnly public override func getRerouteController() -> RerouteControllerInterface {
        return rerouteController ?? super.getRerouteController()
    }

    @_implementationOnly public override func getRerouteDetector() -> RerouteDetectorInterface {
        return rerouteDetector ?? RerouteDetectorSpy()
    }
}
