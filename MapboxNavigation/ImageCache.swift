import Foundation

class ImageCache: BimodalImageCache {

    let memoryCache: NSCache<NSString, UIImage>
    let diskCacheURL: URL = {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.mapboxNavigation.bundleIdentifier!
        return basePath.appendingPathComponent(identifier + ".downloadedImages")
    }()

    let diskAccessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".diskAccess")
    var fileManager: FileManager?

    init() {
        memoryCache = NSCache<NSString, UIImage>()
        memoryCache.name = "In-Memory Image Cache"

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

    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion: NoArgBlock?) {
        let key = cacheKeyForKey(key)

        storeImageInMemoryCache(image, forKey: key)

        let dispatchCompletion = {
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        if toDisk == true {
            guard let fileManager = fileManager else {
                dispatchCompletion()
                return
            }
            let cacheURL = diskCacheURL
            diskAccessQueue.async {
                self.createCacheDirIfNeeded(cacheURL, fileManager: fileManager)

                let data = UIImagePNGRepresentation(image)
                let cacheURL = self.cacheURLWithKey(key)

                do {
                    try data?.write(to: cacheURL)
                } catch {
                    NSLog("================> Failed to write data to URL \(cacheURL)")
                }
                dispatchCompletion()
            }
        } else {
            dispatchCompletion()
        }
    }

    private func storeImageInMemoryCache(_ image: UIImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString, cost: cacheCostForImage(image))
    }

    private func cachePathWithKey(_ key: String) -> String {
        let cacheKey = cacheKeyForKey(key)
        return cacheURLWithKey(cacheKey).absoluteString
    }

    private func cacheURLWithKey(_ key: String) -> URL {
        let cacheKey = cacheKeyForKey(key)
        return diskCacheURL.appendingPathComponent(cacheKey)
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

    func clearMemory() {
        memoryCache.removeAllObjects()
    }

    func clearDisk(completion: NoArgBlock?) {
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

    private func imageFromMemoryCache(forKey key: String?) -> UIImage? {
        guard let key = key, let cacheKey = cacheKeyForKey(key) as NSString! else {
            return nil
        }
        return memoryCache.object(forKey: cacheKey)
    }

    private func imageFromDiskCache(forKey key: String?) -> UIImage? {
        guard let key = key else {
            return nil
        }
        do {
            let data = try Data.init(contentsOf: cacheURLWithKey(key))
            return UIImage(data: data, scale: UIScreen.main.scale)
        } catch {
            NSLog("================> Failed to load data at URL: \(cacheURLWithKey(key))")
            return nil
        }
    }

    private func cacheCostForImage(_ image: UIImage) -> Int {
        return Int(image.size.height * image.size.width * image.scale * image.scale);
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
