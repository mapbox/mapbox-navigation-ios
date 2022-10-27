import MapboxCommon
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private
@testable import MapboxCoreNavigation

class NativeNavigatorSpy: MapboxNavigationNative.Navigator {
    var passedTileStore: TileStore?
    var passedDescriptors: [TilesetDescriptor]?

    var passedNavigationTrackerOptions: PredictiveLocationTrackerOptions?
    var passedDescriptorsTrackerOptions: PredictiveLocationTrackerOptions?

    init() {
        let factory = NativeHandlersFactory(tileStorePath: "", credentials: DirectionsSpy.shared.credentials)
        super.init(config: NativeHandlersFactory.configHandle(),
                   cache: factory.cacheHandle,
                   historyRecorder: nil,
                   router: nil)
    }
    
    override func createPredictiveCacheController(for options: PredictiveLocationTrackerOptions) -> PredictiveCacheController {
        passedNavigationTrackerOptions = options
        return super.createPredictiveCacheController(for: options)
    }

    override func createPredictiveCacheController(for tileStore: TileStore,
                                                  descriptors: [TilesetDescriptor],
                                                  locationTrackerOptions: PredictiveLocationTrackerOptions) -> PredictiveCacheController {
        passedTileStore = tileStore
        passedDescriptors = descriptors
        passedDescriptorsTrackerOptions = locationTrackerOptions
        return super.createPredictiveCacheController(for: locationTrackerOptions)
    }
}

class NativeNavigatorProviderSpy: NativeNavigatorProvider {
    static var navigator: MapboxNavigationNative.Navigator = NativeNavigatorSpy()
}
