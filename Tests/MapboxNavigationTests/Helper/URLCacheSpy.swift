import Foundation
@testable import MapboxNavigation

final class URLCacheSpy: URLCaching {
    var cache = [URL: CachedURLResponse]()
    var clearCacheCalled = false

    func store(_ cachedResponse: CachedURLResponse, for url: URL) {
        cache[url] = cachedResponse
    }

    func response(for url: URL) -> CachedURLResponse? {
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
