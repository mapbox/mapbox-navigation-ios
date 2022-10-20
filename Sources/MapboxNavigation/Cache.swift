import UIKit
import MapboxCommon
import MapboxCommon_Private

public typealias CompletionHandler = () -> Void

public protocol MemoryCache {
    func storeInMemory(_ data: Data, forKey key: String, completion: CompletionHandler?)
    func dataFromMemoryCache(forKey key: String) -> Data?
    func clearMemory(completion: CompletionHandler?)
}

public protocol DiskCache {
    func storeOnDisk(_ data: Data, forKey key: String, completion: CompletionHandler?)
    func dataFromDiskCache(forKey key: String) -> Data?
    func clearDisk(completion: CompletionHandler?)
}

public enum CachingPolicy {
    case memoryOnly
    case diskOnly
    case memoryAndDisk
}

public protocol BimodalCache2: MemoryCache, DiskCache {
    func store(_ data: Data, forKey key: String, policy: CachingPolicy, completion: CompletionHandler?)
    func dataFromCache(forKey key: String) -> Data?
    func clearCache(completion: CompletionHandler?)
}

extension BimodalCache2 {
    func store(_ data: Data, forKey key: String, policy: CachingPolicy, completion: CompletionHandler?) {
        switch policy {
        case .diskOnly:
            storeOnDisk(data, forKey: key, completion: completion)
        case .memoryOnly:
            storeInMemory(data, forKey: key, completion: completion)
        case .memoryAndDisk:
            storeInMemory(data, forKey: key, completion: {
                storeOnDisk(data, forKey: key, completion: completion)
            })
        }
    }
    
    func dataFromCache(forKey key: String) -> Data? {
        return dataFromMemoryCache(forKey: key) ?? dataFromDiskCache(forKey: key)
    }
    
    func clearCache(completion: CompletionHandler?) {
        clearMemory(completion: {
            clearDisk(completion: completion)
        })
    }
}

public typealias DataCompletionHandler = (Data?) -> Void

public protocol BimodalURLCaching: BimodalCache2 {
    
    // + store(cachedURLResponse: for url:)
    
    // + response(for url:) -> CachedURLResponse?
    // + remove Cache(for URL:)
    
    func storeResource(fromURL url: URL, policy: CachingPolicy, completion: DataCompletionHandler?)
    func resourceDataFromCache(forURL url: URL) -> Data?
//    func clearCache(completion: CompletionHandler?)
}

class TileStoreCaching: FileCache {
    let tileStore: TileStore
    
    init(tileStore: TileStore) {
        self.tileStore = tileStore
    }

    func storeResource(fromURL url: URL, completion: DataCompletionHandler?) {
        let options = ResourceLoadOptions(tag: "custom tag?",
                                          flags: .critical,
                                          networkRestriction: .none,
                                          extraOptions: nil)
        tileStore.loadResource(for: .init(url: url.absoluteString,
                                          domain: .navigation),
                               options: options,
                               progressCallback: { _ in },
                               resultCallback: { result in
            if result.isValue() {
                completion?(result.value.data?.getData())
            } else {
                completion?(nil)
            }
        })
    }
    
    func resourceFromCache(forURL url: URL, completion: DataCompletionHandler?) {
        let options = ResourceLoadOptions(tag: "custom tag?",
                                          flags: .skipDataLoading,
                                          networkRestriction: .disallowAll,
                                          extraOptions: nil)
        tileStore.loadResource(for: .init(url: url.absoluteString,
                                          domain: .navigation),
                               options: options,
                               progressCallback: { _ in },
                               resultCallback: { result in
            if result.isValue() {
                completion?(result.value.data?.getData())
            } else {
                completion?(nil)
            }
        })
    }
    // clear resource?
}

class BimodalTileStoreCaching: BimodalURLCaching {
    typealias Key = String
    
    let tileStore: TileStoreCaching
    let memoryCache: ImageCache
    
    init(tileStore: TileStoreCaching, memoryCache: ImageCache) {
        self.tileStore = tileStore
        self.memoryCache = memoryCache
    }
    
    func storeInMemory(_ data: Data, forKey key: String, completion: CompletionHandler?) {
        memoryCache.storeInMemory(data, forKey: key, completion: completion)
    }
    
    func storeOnDisk(_ data: Data, forKey key: String, completion: CompletionHandler?) {
        
    }
    
    func storeResource(fromURL url: URL, policy: CachingPolicy, completion: DataCompletionHandler?) {
        tileStore.storeResource(fromURL: url) {[weak self] data in
            guard let self = self else { return }
            
            if let data = data {
                switch policy {
                case .diskOnly:
                    //do nothing
                    break
                case .memoryAndDisk:
                    self.memoryCache.storeInMemory(data, forKey: url.absoluteString, completion: nil)
                case .memoryOnly:
                    self.memoryCache.storeInMemory(data, forKey: url.absoluteString, completion: nil)
                    // purge from tile store
                }
            }
            
            completion?(data)
        }
    }
    
    func dataFromMemoryCache(forKey key: String) -> Data? {
        return memoryCache.dataFromMemoryCache(forKey: key)
    }
        
    func dataFromDiskCache(forKey key: String) -> Data? {
        return nil
    }
    
    func resourceDataFromCache(forURL url: URL) -> Data? {
        if let data = memoryCache.dataFromMemoryCache(forKey: url.absoluteString) {
            return data
        }
        
        var result: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        tileStore.resourceFromCache(forURL: url,
                                    completion: { data in
            result = data
            semaphore.signal()
        })
        
        _ = semaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(60))
        return result
    }
    
    func clearDisk(completion: CompletionHandler?) {
        // impossible atm.
    }
    
    func clearMemory(completion: CompletionHandler?) {
        memoryCache.clearMemory(completion: completion)
    }
}

/**
 A cache consists of both in-memory and on-disk components, both of which can be reset.
 */
@objc(MBBimodalCache)
public protocol BimodalCache {
    func clearMemory()
    func clearDisk(completion: CompletionHandler?)
}

/**
 A cache which supports storing images
 */
public protocol BimodalImageCache: BimodalCache {
    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion completionBlock: CompletionHandler?)
    func image(forKey: String?) -> UIImage?
}

/**
 A cache which supports storing data
 */
public protocol BimodalDataCache: BimodalCache {
    func store(_ data: Data, forKey key: String, toDisk: Bool, completion completionBlock: CompletionHandler?)
    func data(forKey: String?) -> Data?
}

protocol URLCaching {
    func store(_ cachedResponse: CachedURLResponse, for url: URL)
    func response(for url: URL) -> CachedURLResponse?
    func clearCache()
    func removeCache(for url: URL)
}

/**
 A general purpose URLCache used by `SpriteRepository` implementations.
 */
internal class URLDataCache: URLCaching {
    
//    let tileStore: TileStore
    
    let defaultDiskCacheURL: URL = {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.mapboxNavigation.bundleIdentifier!
        return basePath.appendingPathComponent(identifier).appendingPathComponent("URLDataCache")
    }()
    
    let urlCache: URLCache
    let defaultCapacity = 5 * 1024 * 1024
    
//    func doGood(for url: URL) {
//        let description = ResourceDescription(url: url.absoluteString,
//                                              domain: .navigation)
//        let options = ResourceLoadOptions(tag: "tag?",
//                                          flags: .skipDataLoading, // ??
//                                          networkRestriction: .none,
//                                          extraOptions: nil)
//        tileStore.loadResource(for: description,
//                               options: options,
//                               progressCallback: <#T##ResourceLoadProgressCallback##ResourceLoadProgressCallback##(ResourceLoadProgress) -> Void#>,
//                               resultCallback: <#T##ResourceLoadResultCallback##ResourceLoadResultCallback##(Expected<ResourceLoadResult, ResourceLoadError>) -> Void#>)
//    }
    
    init(memoryCapacity: Int? = nil, diskCapacity: Int? = nil, diskCacheURL: URL? = nil) {
        let memoryCapacity = memoryCapacity ?? defaultCapacity
        let diskCapacity = diskCapacity ?? defaultCapacity
        let diskCacheURL = diskCacheURL ?? defaultDiskCacheURL
        if #available(iOS 13.0, *) {
            urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, directory: diskCacheURL)
        } else {
            urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: diskCacheURL.path)
        }
    }
    
    func store(_ cachedResponse: CachedURLResponse, for url: URL) {
        urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url))
    }
    
    func response(for url: URL) -> CachedURLResponse? {
        return urlCache.cachedResponse(for: URLRequest(url))
    }
    
    func clearCache() {
        urlCache.removeAllCachedResponses()
    }
    
    func removeCache(for url: URL) {
        urlCache.removeCachedResponse(for: URLRequest(url))
    }
}

/**
 A general purpose on-disk cache used by both the ImageCache and DataCache implementations
 */
internal class FileCache: DiskCache {
    func storeOnDisk(_ data: Data, forKey key: String, completion: (() -> Void)?) {
        guard let fileManager = fileManager else {
            completion?()
            return
        }

        diskAccessQueue.async {
            self.createCacheDirIfNeeded(self.diskCacheURL, fileManager: fileManager)
            let cacheURL = self.cacheURLWithKey(key)

            do {
                try data.write(to: cacheURL)
            } catch {
                Log.error("================> Failed to write data to URL \(cacheURL)", category: .navigationUI)
            }
            completion?()
        }
    }
    
    func dataFromDiskCache(forKey key: String) -> Data? {
        do {
            return try Data.init(contentsOf: cacheURLWithKey(key))
        } catch {
            return nil
        }
    }
    
    
    typealias Key = String
    
    let diskCacheURL: URL = {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.mapboxNavigation.bundleIdentifier!
        return basePath.appendingPathComponent(identifier + ".downloadedFiles")
    }()

    let diskAccessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".diskAccess")
    var fileManager: FileManager?

    init() {
        diskAccessQueue.sync {
            fileManager = FileManager()
        }
    }

    /**
     Stores data in the file cache for the given key, and calls the completion handler when finished.
     */
//    public func store(_ data: Data, forKey key: String, completion: CompletionHandler?) {
//        guard let fileManager = fileManager else {
//            completion?()
//            return
//        }
//
//        diskAccessQueue.async {
//            self.createCacheDirIfNeeded(self.diskCacheURL, fileManager: fileManager)
//            let cacheURL = self.cacheURLWithKey(key)
//
//            do {
//                try data.write(to: cacheURL)
//            } catch {
//                Log.error("================> Failed to write data to URL \(cacheURL)", category: .navigationUI)
//            }
//            completion?()
//        }
//    }

    /**
     Returns data from the file cache for the given key, if any.
     */
//    public func dataFromFileCache(forKey key: String?) -> Data? {
//        guard let key = key else {
//            return nil
//        }
//
//        do {
//            return try Data.init(contentsOf: cacheURLWithKey(key))
//        } catch {
//            return nil
//        }
//    }

    /**
     Clears the disk cache by removing and recreating the cache directory, and calls the completion handler when finished.
     */
    public func clearDisk(completion: CompletionHandler?) {
        guard let fileManager = fileManager else {
            return
        }

        let cacheURL = self.diskCacheURL
        self.diskAccessQueue.async {
            do {
                try fileManager.removeItem(at: cacheURL)
            } catch {
                Log.error("================> Failed to remove cache dir: \(cacheURL)", category: .navigationUI)
            }

            self.createCacheDirIfNeeded(cacheURL, fileManager: fileManager)

            completion?()
        }
    }

    func cacheURLWithKey(_ key: String) -> URL {
        let cacheKey = cacheKeyForKey(key)
        return diskCacheURL.appendingPathComponent(cacheKey)
    }

    func cacheKeyForKey(_ key: String) -> String {
        return key.md5
    }

    private func createCacheDirIfNeeded(_ url: URL, fileManager: FileManager) {
        if fileManager.fileExists(atPath: url.absoluteString) == false {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.error("================> Failed to create directory: \(url)", category: .navigationUI)
            }
        }
    }
}
