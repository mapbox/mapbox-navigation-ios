@testable import MapboxNavigationUIKit
import UIKit

final class BimodalImageCacheSpy: BimodalImageCache {
    var cache = [String: UIImage]()
    var clearMemoryCalled = false
    var clearDiskCalled = false

    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion completionBlock: CompletionHandler?) {
        cache[key] = image
        completionBlock?()
    }

    func image(forKey key: String?) -> UIImage? {
        guard let key else { return nil }
        return cache[key]
    }

    func clearMemory() {
        clearMemoryCalled = true
        cache = [:]
    }

    func clearDisk(completion: CompletionHandler?) {
        clearDiskCalled = true
        clearMemory()
        completion?()
    }
}
