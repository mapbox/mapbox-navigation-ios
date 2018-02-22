import Foundation

typealias NoArgBlock = () -> Void

protocol BimodalImageCache {
    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion completionBlock: NoArgBlock?)
    func imageFromCache(forKey: String?) -> UIImage?
    func clearMemory()
    func clearDisk(completion: NoArgBlock?)
}

class ImageRepository {

    public var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default {
        didSet {
            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    public static let shared = ImageRepository.init(withDownloader: ImageDownloader(), cache: ImageCache())

    let imageCache: BimodalImageCache
    fileprivate(set) var imageDownloader: ReentrantImageDownloader

    var useDiskCache = true

    required init(withDownloader downloader: ReentrantImageDownloader, cache: BimodalImageCache) {
        imageDownloader = downloader
        imageCache = cache
    }

    func resetImageCache(_ completion: NoArgBlock?) {
        imageCache.clearMemory()
        imageCache.clearDisk(completion: completion)
    }

    func storeImage(_ image: UIImage, forKey key: String, toDisk: Bool = true) {
        imageCache.store(image, forKey: key, toDisk: toDisk, completion: nil)
    }

    func cachedImageForKey(_ key: String) -> UIImage? {
        return imageCache.imageFromCache(forKey: key)
    }

    func imageWithURL(_ imageURL: URL, cacheKey: String, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cachedImageForKey(cacheKey) {
            completion(cachedImage)
            return
        }

        let _ = imageDownloader.downloadImage(with: imageURL, completion: { [weak self] (image, data, error) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            guard error == nil else {
                completion(image)
                return
            }

            strongSelf.imageCache.store(image, forKey: cacheKey, toDisk: strongSelf.useDiskCache, completion: {
                completion(image)
            })
        })
    }

    func disableDiskCache() {
        useDiskCache = false
    }
}
