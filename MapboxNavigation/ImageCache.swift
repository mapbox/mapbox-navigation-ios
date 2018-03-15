import Foundation

internal class ImageCache: BimodalImageCache {
    let memoryCache: NSCache<NSString, UIImage>
    let fileCache: FileCache

    init() {
        memoryCache = NSCache<NSString, UIImage>()
        memoryCache.name = "In-Memory Image Cache"

        fileCache = FileCache()

        NotificationCenter.default.addObserver(forName: .UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil) { [unowned self] (notif) in
            self.clearMemory()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Image cache

    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion: CompletionHandler?) {
        storeImageInMemoryCache(image, forKey: key)

        if toDisk == true {
            if let data = UIImagePNGRepresentation(image) {
                fileCache.store(data, forKey: key, completion: completion)
            }
        } else {
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
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

    func clearMemory() {
        memoryCache.removeAllObjects()
    }

    func clearDisk(completion: CompletionHandler?) {
        fileCache.clearDisk(completion: completion)
    }

    private func cacheCostForImage(_ image: UIImage) -> Int {
        return Int(image.size.height * image.size.width * image.scale * image.scale);
    }

    private func storeImageInMemoryCache(_ image: UIImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString, cost: cacheCostForImage(image))
    }

    private func imageFromMemoryCache(forKey key: String?) -> UIImage? {
        guard let key = key else {
            return nil
        }
        return memoryCache.object(forKey: key as NSString)
    }

    private func imageFromDiskCache(forKey key: String?) -> UIImage? {
        if let data = fileCache.dataFromFileCache(forKey: key) {
            return UIImage(data: data, scale: UIScreen.main.scale)
        }
        return nil
    }
}
