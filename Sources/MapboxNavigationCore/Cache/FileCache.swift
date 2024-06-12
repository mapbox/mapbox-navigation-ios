import Foundation

final class FileCache: Sendable {
    typealias CompletionHandler = @Sendable () -> Void

    let diskCacheURL: URL = {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.mapboxNavigationUXCore.bundleIdentifier!
        return basePath.appendingPathComponent(identifier + ".downloadedFiles")
    }()

    let diskAccessQueue = DispatchQueue(label: Bundle.mapboxNavigationUXCore.bundleIdentifier! + ".diskAccess")

    /// Stores data in the file cache for the given key, and calls the completion handler when finished.
    public func store(_ data: Data, forKey key: String, completion: CompletionHandler? = nil) {
        diskAccessQueue.async {
            self.createCacheDirIfNeeded(self.diskCacheURL)
            let cacheURL = self.cacheURLWithKey(key)

            do {
                try data.write(to: cacheURL)
            } catch {
                Log.error(
                    "Failed to write data to URL \(cacheURL)",
                    category: .navigationUI
                )
            }
            completion?()
        }
    }

    /// Returns data from the file cache for the given key
    public func data(forKey key: String) -> Data? {
        let cacheKey = cacheURLWithKey(key)
        do {
            return try diskAccessQueue.sync {
                try Data(contentsOf: cacheKey)
            }
        } catch {
            return nil
        }
    }

    /// Clears the disk cache by removing and recreating the cache directory, and calls the completion handler when
    /// finished.
    public func clearDisk(completion: CompletionHandler? = nil) {
        let cacheURL = diskCacheURL
        diskAccessQueue.async {
            do {
                let fileManager = FileManager()
                try fileManager.removeItem(at: cacheURL)
            } catch {
                Log.error(
                    "Failed to remove cache dir: \(cacheURL)",
                    category: .navigationUI
                )
            }

            self.createCacheDirIfNeeded(cacheURL)

            completion?()
        }
    }

    private func cacheURLWithKey(_ key: String) -> URL {
        let cacheKey = cacheKeyForKey(key)
        return diskCacheURL.appendingPathComponent(cacheKey)
    }

    private func cacheKeyForKey(_ key: String) -> String {
        key.sha256
    }

    private func createCacheDirIfNeeded(_ url: URL) {
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: url.absoluteString) == false {
            do {
                try fileManager.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                Log.error(
                    "Failed to create directory: \(url)",
                    category: .navigationUI
                )
            }
        }
    }
}
