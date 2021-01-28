import UIKit

public class DataCache: BimodalDataCache {
    let memoryCache: NSCache<NSString, NSData>
    let fileCache = FileCache()

    public init() {
        memoryCache = NSCache<NSString, NSData>()
        memoryCache.name = "In-Memory Data Cache"
        
        NotificationCenter.default.addObserver(self, selector: #selector(DataCache.clearMemory), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    // MARK: Data cache

    /**
     Stores data in the cache for the given key. If `toDisk` is set to `true`, the completion handler is called following writing the data to disk, otherwise it is called immediately upon storing the data in the memory cache.
     */
    public func store(_ data: Data, forKey key: String, toDisk: Bool, completion: CompletionHandler?) {
        storeDataInMemoryCache(data, forKey: key)

        toDisk == true ? fileCache.store(data, forKey: key, completion: completion) : completion?()
    }

    /**
     Returns data from the cache for the given key, if any. The memory cache is consulted first, followed by the disk cache. If data is found on disk which isn't in memory, it is added to the memory cache.
     */
    public func data(forKey key: String?) -> Data? {
        guard let key = key else {
            return nil
        }

        if let data = dataFromMemoryCache(forKey: key) {
            return data
        }

        if let data = fileCache.dataFromFileCache(forKey: key) {
            storeDataInMemoryCache(data, forKey: key)
            return data
        }

        return nil
    }

    /**
     Clears out the memory cache.
     */
    @objc public func clearMemory() {
        memoryCache.removeAllObjects()
    }

    /**
     Clears the disk cache and calls the completion handler when finished.
     */
    public func clearDisk(completion: CompletionHandler?) {
        fileCache.clearDisk(completion: completion)
    }

    private func storeDataInMemoryCache(_ data: Data, forKey key: String) {
        memoryCache.setObject(data as NSData, forKey: key as NSString)
    }

    private func dataFromMemoryCache(forKey key: String) -> Data? {
        if let data = memoryCache.object(forKey: key as NSString) {
            return data as Data
        }
        return nil
    }
}
