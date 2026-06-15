import Foundation
@testable import MapboxNavigationUIKit

final class URLCacheSpy: URLCaching {
    var cache = [URL: Data]()
    var clearCacheCalled = false

    func store(_ data: Data, for url: URL) {
        cache[url] = data
    }

    func data(for url: URL) -> Data? {
        return cache[url]
    }

    func clearCache() {
        clearCacheCalled = true
        cache = [:]
    }

    func removeCache(for url: URL) {
        cache[url] = nil
    }
}
