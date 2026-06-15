import UIKit

public typealias CompletionHandler = () -> Void

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
    func store(_ data: Data, for url: URL)
    func data(for url: URL) -> Data?
    func clearCache()
    func removeCache(for url: URL)
}

/**
 A general purpose URL data cache used by `SpriteRepository` implementations.
 */
internal class URLDataCache: URLCaching {
    private static var defaultCacheDirectory: URL {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.mapboxNavigation.bundleIdentifier!
        return basePath.appendingPathComponent(identifier)
    }

    private static var defaultDiskCacheURL: URL {
        return defaultCacheDirectory.appendingPathComponent("URLDataCache-v2")
    }

    private static var legacyDiskCacheURL: URL {
        return defaultCacheDirectory.appendingPathComponent("URLDataCache")
    }
    
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskCacheURL: URL
    private static let defaultCapacity = 5 * 1024 * 1024
    private let memoryCapacity: Int
    private let diskCapacity: Int
    private let fileManager: FileManager
    private let diskAccessQueue: DispatchQueue
    private let cacheLock = NSLock()
    private var memoryCosts = [String: Int]()
    private var memoryUsage = 0
    
    var currentMemoryUsage: Int {
        cacheLock.lock()
        defer {
            cacheLock.unlock()
        }
        return memoryUsage
    }
    
    var currentDiskUsage: Int {
        diskAccessQueue.sync {
            return diskUsage()
        }
    }
    
    init(memoryCapacity: Int? = nil, diskCapacity: Int? = nil, diskCacheURL: URL? = nil) {
        // Only the default production cache has a known legacy URLCache directory to remove.
        let shouldRemoveLegacyCache = diskCacheURL == nil
        self.memoryCapacity = memoryCapacity ?? Self.defaultCapacity
        self.diskCapacity = diskCapacity ?? Self.defaultCapacity
        self.diskCacheURL = diskCacheURL ?? Self.defaultDiskCacheURL
        self.fileManager = FileManager()
        self.diskAccessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".URLDataCache.diskAccess")
        memoryCache.name = "In-Memory URL Data Cache"
        memoryCache.totalCostLimit = self.memoryCapacity
        diskAccessQueue.sync {
            if shouldRemoveLegacyCache {
                // The old cache used URLCache and may contain CFNetwork metadata that can crash while being rehydrated.
                // Remove it by file path only; do not open it through URLCache.
                removeLegacyCacheIfNeeded()
            }
            createCacheDirIfNeeded()
        }
    }

    func store(_ data: Data, for url: URL) {
        let key = cacheKey(for: url)
        storeDataInMemoryCache(data, forKey: key)

        guard diskCapacity > 0 else {
            return
        }

        diskAccessQueue.sync {
            createCacheDirIfNeeded()
            do {
                try data.write(to: cacheURL(withKey: key))
                pruneDiskCacheIfNeeded()
            } catch {
                Log.debug("Failed to write data to URL cache: \(error.localizedDescription).", category: .navigationUI)
            }
        }
    }

    func data(for url: URL) -> Data? {
        let key = cacheKey(for: url)

        if let data = dataFromMemoryCache(forKey: key) {
            return data
        }

        let diskData = diskAccessQueue.sync {
            return dataFromDiskCache(forKey: key)
        }

        if let diskData {
            storeDataInMemoryCache(diskData, forKey: key)
        }

        return diskData
    }

    func clearCache() {
        cacheLock.lock()
        memoryCache.removeAllObjects()
        memoryCosts.removeAll()
        memoryUsage = 0
        cacheLock.unlock()

        diskAccessQueue.sync {
            if fileManager.fileExists(atPath: diskCacheURL.path) {
                do {
                    try fileManager.removeItem(at: diskCacheURL)
                } catch {
                    Log.debug("Failed to remove URL cache directory: \(diskCacheURL).", category: .navigationUI)
                }
            }
            createCacheDirIfNeeded()
        }
    }

    func removeCache(for url: URL) {
        let key = cacheKey(for: url)
        removeDataFromMemoryCache(forKey: key)

        diskAccessQueue.sync {
            let cacheURL = cacheURL(withKey: key)
            if fileManager.fileExists(atPath: cacheURL.path) {
                do {
                    try fileManager.removeItem(at: cacheURL)
                } catch {
                    Log.debug("Failed to remove URL cache file: \(cacheURL).", category: .navigationUI)
                }
            }
        }
    }

    private func storeDataInMemoryCache(_ data: Data, forKey key: String) {
        guard data.count <= memoryCapacity else {
            removeDataFromMemoryCache(forKey: key)
            return
        }

        cacheLock.lock()
        defer {
            cacheLock.unlock()
        }

        let previousCost = memoryCosts[key] ?? 0
        memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        memoryCosts[key] = data.count
        memoryUsage += data.count - previousCost
    }

    private func dataFromMemoryCache(forKey key: String) -> Data? {
        cacheLock.lock()
        defer {
            cacheLock.unlock()
        }

        guard let data = memoryCache.object(forKey: key as NSString) else {
            return nil
        }
        return data as Data
    }

    private func removeDataFromMemoryCache(forKey key: String) {
        cacheLock.lock()
        defer {
            cacheLock.unlock()
        }

        memoryCache.removeObject(forKey: key as NSString)
        memoryUsage -= memoryCosts.removeValue(forKey: key) ?? 0
    }

    private func dataFromDiskCache(forKey key: String) -> Data? {
        let url = cacheURL(withKey: key)

        do {
            let data = try Data(contentsOf: url)
            // Treat disk reads as access for oldest-file pruning.
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            return data
        } catch {
            return nil
        }
    }

    private func cacheKey(for url: URL) -> String {
        return url.absoluteString.md5
    }

    private func cacheURL(withKey key: String) -> URL {
        return diskCacheURL.appendingPathComponent(key)
    }

    private func createCacheDirIfNeeded() {
        guard fileManager.fileExists(atPath: diskCacheURL.path) == false else {
            return
        }

        do {
            try fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Log.debug("Failed to create URL cache directory: \(diskCacheURL).", category: .navigationUI)
        }
    }

    private func removeLegacyCacheIfNeeded() {
        let legacyDiskCacheURL = Self.legacyDiskCacheURL
        guard fileManager.fileExists(atPath: legacyDiskCacheURL.path) else {
            return
        }

        try? fileManager.removeItem(at: legacyDiskCacheURL)
    }

    private func pruneDiskCacheIfNeeded() {
        var cacheFiles = diskCacheFiles()
        var totalSize = cacheFiles.reduce(0) { $0 + $1.size }

        guard totalSize > diskCapacity else {
            return
        }

        cacheFiles.sort { $0.modificationDate < $1.modificationDate }
        for cacheFile in cacheFiles where totalSize > diskCapacity {
            do {
                try fileManager.removeItem(at: cacheFile.url)
                totalSize -= cacheFile.size
            } catch {
                Log.debug("Failed to remove URL cache file: \(cacheFile.url).", category: .navigationUI)
            }
        }
    }

    private func diskUsage() -> Int {
        return diskCacheFiles().reduce(0) { $0 + $1.size }
    }

    private func diskCacheFiles() -> [(url: URL, size: Int, modificationDate: Date)] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let size = values.fileSize else {
                return nil
            }
            return (url, size, values.contentModificationDate ?? .distantPast)
        }
    }
}

/**
 A general purpose on-disk cache used by both the ImageCache and DataCache implementations
 */
internal class FileCache {
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
    public func store(_ data: Data, forKey key: String, completion: CompletionHandler?) {
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

    /**
     Returns data from the file cache for the given key, if any.
     */
    public func dataFromFileCache(forKey key: String?) -> Data? {
        guard let key = key else {
            return nil
        }

        do {
            return try Data.init(contentsOf: cacheURLWithKey(key))
        } catch {
            return nil
        }
    }

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
