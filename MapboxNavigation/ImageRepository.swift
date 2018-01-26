import Foundation
import SDWebImage

class ImageRepository {

    public static let shared = ImageRepository()

    static var useDiskCache = true

    let imageCache = SDImageCache.shared()
    let imageDownloader = SDWebImageDownloader.shared()

    func resetImageCache() {
        imageCache.clearMemory()
        let semaphore = DispatchSemaphore(value: 1)
        imageCache.clearDisk {
            semaphore.signal()
        }
        let _ = semaphore.wait(timeout: .distantFuture)
    }

    func storeImage(_ image: UIImage, forKey key: String?, toDisk: Bool = true) {
        imageCache.store(image, forKey: key, toDisk: toDisk)
        imageCache.store(image, forKey: key, toDisk: toDisk)
    }

    func cachedImageForKey(_ key: String) -> UIImage? {
        return imageCache.imageFromCache(forKey: key)
    }

    func downloadImageWithURL(_ imageURL: URL, cacheKey: String, completion: @escaping (UIImage?) -> Void) {
        imageDownloader.downloadImage(with: imageURL, options: [], progress: nil, completed: { [weak self] (image, data, error, successful) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            strongSelf.imageCache.store(image, forKey: cacheKey, toDisk: ImageRepository.useDiskCache, completion: {
                completion(image)
            })
        })
    }

    static func disableDiskCache() {
        useDiskCache = false
    }

}
