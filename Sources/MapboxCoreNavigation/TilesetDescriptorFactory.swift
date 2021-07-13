import Foundation
import MapboxNavigationNative
import MapboxDirections

extension TilesetDescriptorFactory {
    /**
     Gets TilesetDescriptor which corresponds to current Navigator dataset and the specified `version`.
     - parameter cacheLocation: A `Location` where cache data is stored.
     - parameter version: TilesetDescriptor version.
     */
    public class func getSpecificVersion(forCacheLocation cacheLocation: TileStoreConfiguration.Location = .default, version: String) -> TilesetDescriptor {
        let cacheHandle = NativeHandlersFactory(tileStorePath: cacheLocation.tileStoreURL?.path ?? "").cacheHandle
        return getSpecificVersion(forCache: cacheHandle, version: version)
    }

    /**
     Gets TilesetDescriptor that corresponds to the latest available version of routing tiles.

     It is intended to be used when creating off-line tile packs.

     - Parameters:
       - location: A `Location` where cache data is stored.
       - completionQueue: A DispatchQueue on which the completion will be called.
       - completion: A completion that will be used to pass the latest tileset descriptor.
     */
    public class func getLatest(forCacheLocation cacheLocation: TileStoreConfiguration.Location = .default,
                                completionQueue: DispatchQueue = .main,
                                completion: @escaping (_ latestTilesetDescriptor: TilesetDescriptor) -> Void) {
        /**
         NOTE: The latest tile descriptor is resolved asynchronously in `MBNNCacheHandle,` but there is no way to wait
         until the latest descriptor is resolved in the cache handle. Until we have such capabilities,  we deploy
         a quick fix to let `MBNNCacheHandle` resolve the latest descriptor by waiting for  X seconds until we ask it
         for the descriptor. We fallback to this workaround only when `Navigator` hasn't been created yet, or
         the navigator isn't in the appropriate state for requested tile descriptor.
         */

        let tileStoreUrl = cacheLocation.tileStoreURL
        if Navigator.isSharedInstanceCreated,
           Navigator.tilesURL == tileStoreUrl,
           case .nominal = Navigator.shared.tileVersionState {
            completionQueue.async {
                completion(getLatestForCache(Navigator.shared.cacheHandle))
            }
        }
        else {
            let cacheHandle = NativeHandlersFactory(tileStorePath: tileStoreUrl?.path ?? "").cacheHandle
            completionQueue.asyncAfter(deadline: .now() + 1) {
                completion(getLatestForCache(cacheHandle))
            }
        }
    }
}
