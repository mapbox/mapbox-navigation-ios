import Foundation

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
@objc(MBBimodalImageCache)
public protocol BimodalImageCache: BimodalCache {
    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion completionBlock: CompletionHandler?)
    func image(forKey: String?) -> UIImage?
}

/**
 A cache which supports storing data
 */
@objc(MBBimodalDataCache)
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

    public func store(_ data: Data, forKey key: String, completion: CompletionHandler?) {
        let dispatchCompletion = {
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
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

    }

    public func dataFromFileCache(forKey key: String?) -> Data? {
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

            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    private func cachePathWithKey(_ key: String) -> String {
        let cacheKey = cacheKeyForKey(key)
        return cacheURLWithKey(cacheKey).absoluteString
    }

    private func cacheURLWithKey(_ key: String) -> URL {
        let cacheKey = cacheKeyForKey(key)
        return diskCacheURL.appendingPathComponent(cacheKey)
    }

    private func cacheKeyForKey(_ key: String) -> String {
        if let keyAsURL = URL(string: key) {
            return String.init(keyAsURL.lastPathComponent.hashValue)
        }
        return String.init(key.hashValue)
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
