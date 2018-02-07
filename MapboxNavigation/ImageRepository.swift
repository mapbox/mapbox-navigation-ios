import Foundation
import SDWebImage

typealias ImageDownloadCompletionBlock = (UIImage?, Data?, Error?, Bool) -> Void

protocol ReentrantImageDownloader {
    func downloadImage(with url: URL?, options: SDWebImageDownloaderOptions, progress progressBlock: SDWebImageDownloaderProgressBlock?, completed completedBlock: ImageDownloadCompletionBlock?) -> SDWebImageDownloadToken?
    func setOperationClass(_ klass: AnyClass?)
}

typealias NoArgBlock = () -> Void

protocol BimodalImageCache {
    func store(_ image: UIImage?, forKey key: String?, toDisk: Bool, completion completionBlock: NoArgBlock?)
    func imageFromCache(forKey: String?) -> UIImage?
    func clearMemory()
    func clearDisk(onCompletion completion: (() -> Void)?)
}

extension SDImageCache: BimodalImageCache {}

extension SDWebImageDownloader: ReentrantImageDownloader {}

class ImageRepository {

    public var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default {
        didSet {
            imageDownloader = SDWebImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    public static let shared = ImageRepository.init(withDownloader: SDWebImageDownloader.shared(), cache: ImageCache())

    let imageCache: BimodalImageCache
    fileprivate(set) var imageDownloader: ReentrantImageDownloader

    var useDiskCache = true

    required init(withDownloader downloader: ReentrantImageDownloader, cache: BimodalImageCache) {
        imageDownloader = downloader
        imageCache = cache
    }

    func resetImageCache(_ completion: NoArgBlock?) {
        imageCache.clearMemory()
        imageCache.clearDisk(onCompletion: completion)
    }

    func storeImage(_ image: UIImage, forKey key: String?, toDisk: Bool = true) {
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

        let _ = imageDownloader.downloadImage(with: imageURL, options: [], progress: nil, completed: { [weak self] (image, data, error, successful) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
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
