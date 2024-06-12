import Foundation
import UIKit

protocol SyncBimodalCache {
    func clear(mode: CacheMode)
    func store(data: Data, key: String, mode: CacheMode)

    subscript(key: String) -> Data? { get }
}

struct CacheMode: OptionSet {
    var rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let InMemory = CacheMode(rawValue: 1 << 0)
    static let OnDisk = CacheMode(rawValue: 1 << 1)
}

final class MapboxSyncBimodalCache: SyncBimodalCache, @unchecked Sendable {
    private let accessLock: NSLock
    private let memoryCache: NSCache<NSString, NSData>
    private let fileCache = FileCache()

    public init() {
        self.accessLock = .init()
        self.memoryCache = NSCache<NSString, NSData>()
        memoryCache.name = "In-Memory Data Cache"

        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.clearMemory),
                name: UIApplication.didReceiveMemoryWarningNotification,
                object: nil
            )
        }
    }

    @objc
    func clearMemory() {
        accessLock.withLock {
            memoryCache.removeAllObjects()
        }
    }

    func clear(mode: CacheMode) {
        accessLock.withLock {
            if mode.contains(.InMemory) {
                memoryCache.removeAllObjects()
            } else if mode.contains(.OnDisk) {
                fileCache.clearDisk()
            }
        }
    }

    func store(data: Data, key: String, mode: CacheMode) {
        accessLock.withLock {
            if mode.contains(.InMemory) {
                memoryCache.setObject(
                    data as NSData,
                    forKey: key as NSString
                )
            } else if mode.contains(.OnDisk) {
                fileCache.store(
                    data,
                    forKey: key
                )
            }
        }
    }

    subscript(key: String) -> Data? {
        accessLock.withLock {
            return memoryCache.object(
                forKey: key as NSString
            ) as Data? ??
                fileCache.data(
                    forKey: key
                )
        }
    }
}
