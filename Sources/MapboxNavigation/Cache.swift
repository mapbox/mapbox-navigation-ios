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
                NSLog("================> Failed to write data to URL \(cacheURL)")
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
                NSLog("================> Failed to remove cache dir: \(cacheURL)")
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
                NSLog("================> Failed to create directory: \(url)")
            }
        }
    }
}
