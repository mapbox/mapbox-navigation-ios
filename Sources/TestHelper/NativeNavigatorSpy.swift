import MapboxCommon
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private
@testable import MapboxCoreNavigation

public class NativeNavigatorSpy: MapboxNavigationNative.Navigator {
    public var passedTileStore: TileStore?
    public var passedDescriptors: [TilesetDescriptor]?
    public var passedCacheOptions: PredictiveCacheControllerOptions?

    public var passedNavigationTrackerOptions: PredictiveLocationTrackerOptions?
    public var passedDescriptorsTrackerOptions: PredictiveLocationTrackerOptions?
    public var passedDatasetTrackerOptions: PredictiveLocationTrackerOptions?

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
}

public class NativeNavigatorProviderSpy: NativeNavigatorProvider {
    public static var navigator: MapboxNavigationNative.Navigator = NativeNavigatorSpy()
}
