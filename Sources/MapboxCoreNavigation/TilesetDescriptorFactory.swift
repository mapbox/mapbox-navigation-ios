import Foundation
import MapboxNavigationNative
import MapboxDirections

extension TilesetDescriptorFactory {
    /**
     Gets TilesetDescriptor which corresponds to current Navigator dataset and the specified `version`.
     - parameter cacheLocation: A `Location` where cache data is stored.
     - parameter version: TilesetDescriptor version.
     */
    open class func getSpecificVersion(forCacheLocation cacheLocation: TileStoreConfiguration.Location = .default, version: String) -> TilesetDescriptor {
        let cacheHandle = NativeHandlersFactory(tileStorePath: cacheLocation.tileStoreURL?.path ?? "").cacheHandle
        return getSpecificVersion(forCache: cacheHandle, version: version)
    }

    /**
     Gets TilesetDescriptor which corresponds to the latest availble version of routing tiles.
     
     Intended for using when creating off-line tile packs.
     
     - parameter location: A `Location` where cache data is stored.
     */
    open class func getLatest(forCacheLocation cacheLocation: TileStoreConfiguration.Location = .default) -> TilesetDescriptor {
        let cacheHandle = NativeHandlersFactory(tileStorePath: cacheLocation.tileStoreURL?.path ?? "").cacheHandle
        return getLatestForCache(cacheHandle)
    }
}
