import Foundation
import MapboxCommon
import MapboxNavigationNative
import MapboxDirections

extension TilesetDescriptorFactory {
    /**
     Gets TilesetDescriptor which corresponds to current Navigator dataset and the specified `version`.
     - Parameters:
       - version: TilesetDescriptor version.
       - completionQueue: A DispatchQueue on which the completion will be called.
       - datasetProfileIdentifier: Profile setting, used for selecting tiles type for navigation.
       - completion: A completion that will be used to pass the tileset descriptor.
     */
    public class func getSpecificVersion(version: String,
                                         completionQueue: DispatchQueue = .main,
                                         datasetProfileIdentifier: ProfileIdentifier = .automobile,
                                         completion: @escaping (TilesetDescriptor) -> Void) {
        let factory = NativeHandlersFactory(tileStorePath: NavigationSettings.shared.tileStoreConfiguration.navigatorLocation.tileStoreURL?.path ?? "",
                                            credentials: NavigationSettings.shared.directions.credentials,
                                            datasetProfileIdentifier: datasetProfileIdentifier)
        completionQueue.async {
            completion(getSpecificVersion(forCache: factory.cacheHandle, version: version))
        }
    }

    /**
     Gets TilesetDescriptor that corresponds to the latest available version of routing tiles.

     It is intended to be used when creating off-line tile packs.

     - Parameters:
       - completionQueue: A DispatchQueue on which the completion will be called.
       - datasetProfileIdentifier: Profile setting, used for selecting tiles type for navigation.
       - completion: A completion that will be used to pass the latest tileset descriptor.
     */
    public class func getLatest(completionQueue: DispatchQueue = .main,
                                datasetProfileIdentifier: ProfileIdentifier = .automobile,
                                completion: @escaping (_ latestTilesetDescriptor: TilesetDescriptor) -> Void) {
        let factory = NativeHandlersFactory(tileStorePath: NavigationSettings.shared.tileStoreConfiguration.navigatorLocation.tileStoreURL?.path ?? "",
                                            credentials: NavigationSettings.shared.directions.credentials,
                                            datasetProfileIdentifier: datasetProfileIdentifier)
        completionQueue.async {
            completion(getLatestForCache(factory.cacheHandle))
        }
    }
}
