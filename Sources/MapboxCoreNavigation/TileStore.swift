import MapboxCommon
import MapboxNavigationNative


extension TileStore {
    public typealias ContainsCompletion = (Bool?) -> Void
    
    /**
     Checks if all `OfflineRegion`s in current `TileStore` contain latest version of Navigation tiles.
     
     This method iterates all existing `OfflineRegion`s. If any of the regions have older version of nav tiles or do not have them at all - it will report `false`.
     
     - parameter completion: A completion callback, reporting the result. `nil` is returned if error occured during the process.
     
     - Note:
     The user-provided callbacks will be executed on a TileStore-controlled
     worker thread; it is the responsibility of the user to dispatch to a
     user-controlled thread.
     */
    public func containsLatestNavigationTiles(completion: @escaping ContainsCompletion) {
        TilesetDescriptorFactory.getLatest(completionQueue: .main) { latestTilesetDescriptor in
            self.__getAllTileRegions { expected in
                if expected.isValue(), let regions = expected.value as? Array<TileRegion> {
                    let lock = NSLock()
                    var count = regions.count
                    var result: Bool? = true

                    for region in regions {
                        self.__tileRegionContainsDescriptors(forId: region.id,
                                                             descriptors: [latestTilesetDescriptor],
                                                             callback: { expected in
                            lock.lock()

                            if expected.isValue(),
                               let value = expected.value as? NSNumber {
                                result = result.map { $0 && value.boolValue }
                            } else if expected.isError() {
                                result = nil
                            } else {
                                assertionFailure("Unexpected value or error: \(String(describing: expected)), expected: \(NSNumber.self)")
                                result = nil
                            }

                            count -= 1
                            if count == 0 {
                                completion(result)
                            }
                            lock.unlock()
                        })
                    }
                } else if expected.isError() {
                    completion(nil)
                } else {
                    assertionFailure("Unexpected value or error: \(expected), expected: \(Array<TileRegion>.self)")
                    completion(nil)
                }
            }
        }
    }
    
    /**
     Checks if a tile region with the given id contains latest version of Navigation tiles.
     
     - parameter regionId: The tile region identifier.
     - parameter completion: The result callback. If error occured - `nil` will be returned.
     
     - Note:
     The user-provided callbacks will be executed on a TileStore-controlled
     worker thread; it is the responsibility of the user to dispatch to a
     user-controlled thread.
     */
    public func tileRegionContainsLatestNavigationTiles(forId regionId: String,
                                                        completion: @escaping ContainsCompletion) {
        TilesetDescriptorFactory.getLatest(completionQueue: .main) { latestTilesetDescriptor in
            self.__tileRegionContainsDescriptors(forId: regionId,
                                                 descriptors: [latestTilesetDescriptor],
                                                 callback: { expected in
                if expected.isValue(),
                   let value = expected.value as? NSNumber {
                    completion(value.boolValue)
                } else if expected.isError() {
                    completion(nil)
                } else {
                    assertionFailure("Unexpected value or error: \(expected), expected: \(NSNumber.self)")
                    completion(nil)
                }
            })
        }
    }
}
