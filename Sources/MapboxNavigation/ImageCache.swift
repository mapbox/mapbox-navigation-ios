import UIKit

internal class ImageMemory: NSObject, NSDiscardableContent {
    func beginContentAccess() -> Bool { return true }
    func endContentAccess() { }
    func discardContentIfPossible() {}
    func isContentDiscarded() -> Bool { return false }
    let image: UIImage
    
    init(_ image: UIImage) {
        self.image = image
    }
}

internal class ImageCache: MemoryCache {
    func storeInMemory(_ data: Data, forKey key: String, completion: CompletionHandler?) {
        guard let image = UIImage(data: data) else {
            completion?()
            return
        }
        store(image, forKey: key, completion: completion)
    }
    
    func dataFromMemoryCache(forKey key: String) -> Data? {
        return image(forKey: key)?.pngData()
    }
    
    func clearMemory(completion: CompletionHandler?) {
        memoryCache.removeAllObjects()
        completion?()
    }
    
    typealias Key = String
    //BimodalImageCache {
    let memoryCache: NSCache<NSString, ImageMemory>
//    let fileCache: FileCache

    init() {
        memoryCache = NSCache<NSString, ImageMemory>()
        memoryCache.name = "In-Memory Image Cache"

//        fileCache = FileCache()

        NotificationCenter.default.addObserver(self, selector: #selector(DataCache.clearMemory), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    // MARK: Image cache

    /**
     Stores an image in the cache for the given key. If `toDisk` is set to `true`, the completion handler is called following writing the image to disk, otherwise it is called immediately upon storing the image in the memory cache.
     */
    public func store(_ image: UIImage, forKey key: String, completion: CompletionHandler?) {
        storeImageInMemoryCache(image, forKey: key)
        
        completion?()
        
//        guard toDisk == true, let data = image.pngData() else {
//            completion?()
//            return
//        }
        
//        fileCache.store(data, forKey: key, completion: completion)
//        fileCache.storeOnDisk(data, forKey: key, completion: completion)
    }

    /**
     Returns an image from the cache for the given key, if any. The memory cache is consulted first, followed by the disk cache. If an image is found on disk which isn't in memory, it is added to the memory cache.
     */
    public func image(forKey key: String?) -> UIImage? {
        guard let key = key else {
            return nil
        }

        if let image = imageFromMemoryCache(forKey: key) {
            return image
        }

//        if let image = imageFromDiskCache(forKey: key) {
//            storeImageInMemoryCache(image, forKey: key)
//            return image
//        }

        return nil
    }

    /**
     Clears out the memory cache.
     */
//    public func clearMemory() {
//        memoryCache.removeAllObjects()
//    }

    /**
     Clears the disk cache and calls the completion handler when finished.
     */
//    public func clearDisk(completion: CompletionHandler?) {
//        fileCache.clearDisk(completion: completion)
//    }

    private func storeImageInMemoryCache(_ image: UIImage, forKey key: String) {
        let imageMemory = ImageMemory(image)
        memoryCache.setObject(imageMemory, forKey: key as NSString, cost: image.memoryCost)
    }

    private func imageFromMemoryCache(forKey key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)?.image
    }

//    private func imageFromDiskCache(forKey key: String?) -> UIImage? {
////        if let data = fileCache.dataFromFileCache(forKey: key) {
//        if let key = key,
//           let data = fileCache.dataFromDiskCache(forKey: key) {
//            return UIImage(data: data, scale: UIScreen.main.scale)
//        }
//        return nil
//    }
}
