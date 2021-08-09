import Foundation
import MapboxNavigationNative
import MapboxDirections

extension TilesetDescriptorFactory {
    /**
     Gets TilesetDescriptor which corresponds to current Navigator dataset and the specified `version`.
     - Parameters:
       - version: TilesetDescriptor version.
       - completionQueue: A DispatchQueue on which the completion will be called.
       - completion: A completion that will be used to pass the tileset descriptor.
     */
    public class func getSpecificVersion(version: String,
                                         completionQueue: DispatchQueue = .main,
                                         completion: @escaping (TilesetDescriptor) -> Void) {
        let cacheHandle = Navigator.shared.cacheHandle
        completionQueue.async {
            completion(getSpecificVersion(forCache: cacheHandle, version: version))
        }
    }

    /**
     Gets TilesetDescriptor that corresponds to the latest available version of routing tiles.

     It is intended to be used when creating off-line tile packs.

     - Parameters:
       - completionQueue: A DispatchQueue on which the completion will be called.
       - completion: A completion that will be used to pass the latest tileset descriptor.
     */
    public class func getLatest(completionQueue: DispatchQueue = .main,
                                completion: @escaping (_ latestTilesetDescriptor: TilesetDescriptor) -> Void) {
        let cacheHandle = Navigator.shared.cacheHandle

        completionQueue.async {
            completion(getLatestForCache(cacheHandle))
        }
    }
}
