import Foundation

internal class DataCache: BimodalDataCache {
    let memoryCache: NSCache<NSString, NSData>
    let fileCache: FileCache

    init() {
        memoryCache = NSCache<NSString, NSData>()
        memoryCache.name = "In-Memory Data Cache"

        fileCache = FileCache()

        NotificationCenter.default.addObserver(forName: .UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil) { [unowned self] (notif) in
            self.clearMemory()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Data cache

    func store(_ data: Data, forKey key: String, toDisk: Bool, completion: CompletionHandler?) {
        storeDataInMemoryCache(data, forKey: key)
        if toDisk == true {
            fileCache.store(data, forKey: key, completion: completion)
        } else {
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func dataFromCache(forKey key: String?) -> Data? {
        guard let key = key else {
            return nil
        }
        if let data = dataFromMemoryCache(forKey: key) {
            return data
        }

        if let data = fileCache.dataFromFileCache(forKey: key) {
            //TODO: add test
            storeDataInMemoryCache(data, forKey: key)
            return data
        }

        return nil
    }

    func clearMemory() {
        memoryCache.removeAllObjects()
    }

    func clearDisk(completion: CompletionHandler?) {
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
