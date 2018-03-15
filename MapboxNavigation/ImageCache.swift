import Foundation

class ImageCache: BimodalImageCache, BimodalDataCache {

    let memoryCache: NSCache<NSString, NSData>
    let diskCacheURL: URL = {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.mapboxNavigation.bundleIdentifier!
        return basePath.appendingPathComponent(identifier + ".downloadedImages")
    }()

    let diskAccessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".diskAccess")
    var fileManager: FileManager?

    init() {
        memoryCache = NSCache<NSString, NSData>()
        memoryCache.name = "In-Memory Cache"

        diskAccessQueue.sync {
            fileManager = FileManager()
        }

        NotificationCenter.default.addObserver(forName: .UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil) { [unowned self] (notif) in
            self.clearMemory()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Data cache

    func store(_ data: Data, forKey key: String, toDisk: Bool, completion: CompletionHandler?) {
        let dispatchCompletion = {
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
        storeDataInMemoryCache(data, forKey: key)
        if toDisk == true {
            guard let fileManager = fileManager else {
                dispatchCompletion()
                return
            }
            let cacheURL = diskCacheURL
            diskAccessQueue.async {
                self.createCacheDirIfNeeded(cacheURL, fileManager: fileManager)
                let cacheURL = self.cacheURLWithKey(key)

                do {
                    try data.write(to: cacheURL)
                } catch {
                    NSLog("================> Failed to write data to URL \(cacheURL)")
                }
                dispatchCompletion()
            }
        } else {
            dispatchCompletion()
        }
    }

    func dataFromCache(forKey key: String?) -> Data? {
        if let data = dataFromMemoryCache(forKey: key) {
            return data
        }

        if let data = dataFromDiskCache(forKey: key) {
            //TODO: add test
            storeDataInMemoryCache(data, forKey: key!)
            return data
        }

        return nil
    }

    private func storeDataInMemoryCache(_ data: Data, forKey key: String) {
        memoryCache.setObject(data as NSData, forKey: key as NSString)
    }

    private func dataFromMemoryCache(forKey key: String?) -> Data? {
        guard let key = key, let cacheKey = cacheKeyForKey(key) as NSString! else {
            return nil
        }
        if let data = memoryCache.object(forKey: cacheKey) {
            return data as Data
        }
        return nil
    }

    private func dataFromDiskCache(forKey key: String?) -> Data? {
        guard let key = key else {
            return nil
        }
        do {
            return try Data.init(contentsOf: cacheURLWithKey(key))
        } catch {
            NSLog("No viable data in disk cache for URL: %@", key)
            return nil
        }
    }

    // MARK: Image cache

    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion: CompletionHandler?) {
        let key = cacheKeyForKey(key)
        storeImageInMemoryCache(image, forKey: key)
        if let data = UIImagePNGRepresentation(image) {
            store(data, forKey: key, toDisk: toDisk, completion: completion)
        }
    }

    func imageFromCache(forKey key: String?) -> UIImage? {
        if let image = imageFromMemoryCache(forKey: key) {
            return image
        }

        if let image = imageFromDiskCache(forKey: key) {
            //TODO: add test
            storeImageInMemoryCache(image, forKey: key!)
            return image
        }

        return nil
    }

    private func storeImageInMemoryCache(_ image: UIImage, forKey key: String) {
        let data = UIImagePNGRepresentation(image)! as NSData
        memoryCache.setObject(data, forKey: key as NSString)
    }

    private func imageFromMemoryCache(forKey key: String?) -> UIImage? {
        guard let key = key, let cacheKey = cacheKeyForKey(key) as NSString! else {
            return nil
        }
        if let data = memoryCache.object(forKey: cacheKey) {
            return UIImage.init(data: data as Data, scale: UIScreen.main.scale)
        }
        return nil
    }

    private func imageFromDiskCache(forKey key: String?) -> UIImage? {
        if let data = dataFromDiskCache(forKey: key) {
            return UIImage(data: data, scale: UIScreen.main.scale)
        }
        return nil
    }

    private func cacheCostForImage(_ image: UIImage) -> Int {
        return Int(image.size.height * image.size.width * image.scale * image.scale);
    }

    // MARK: Common

    private func cachePathWithKey(_ key: String) -> String {
        let cacheKey = cacheKeyForKey(key)
        return cacheURLWithKey(cacheKey).absoluteString
    }

    private func cacheURLWithKey(_ key: String) -> URL {
        let cacheKey = cacheKeyForKey(key)
        return diskCacheURL.appendingPathComponent(cacheKey)
    }

    func clearMemory() {
        memoryCache.removeAllObjects()
    }

    func clearDisk(completion: CompletionHandler?) {
        guard let fileManager = fileManager else {
            return
        }
        let cacheURL = self.diskCacheURL
        self.diskAccessQueue.async {
            do {
                try fileManager.removeItem(at: cacheURL)
            } catch {
                NSLog("================> Failed to remove cache dir: \(cacheURL)")
            }

            self.createCacheDirIfNeeded(cacheURL, fileManager: fileManager)

            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    private func cacheKeyForKey(_ key: String) -> String {
        if let keyAsURL = URL(string: key) {
            return keyAsURL.lastPathComponent
        }
        return key
    }

    private func createCacheDirIfNeeded(_ url: URL, fileManager: FileManager) {
        if fileManager.fileExists(atPath: url.absoluteString) == false {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // TODO: unsure of the best strategy to catch/handle this case at the moment
                NSLog("================> Failed to create directory: \(url)")
            }
        }
    }
}
