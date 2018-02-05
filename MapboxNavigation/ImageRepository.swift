import Foundation
import SDWebImage

protocol ImageDownloader {
    func downloadImage(with url: URL?, options: SDWebImageDownloaderOptions, progress progressBlock: SDWebImageDownloaderProgressBlock?, completed completedBlock: SDWebImageDownloaderCompletedBlock?) -> SDWebImageDownloadToken?
    func setOperationClass(_ klass: AnyClass?)
}

protocol ImageCache {
    func store(_ image: UIImage?, forKey key: String?, toDisk: Bool, completion completionBlock: SDWebImageNoParamsBlock?)
    func imageFromCache(forKey: String?) -> UIImage?
    func clearMemory()
    func clearDisk(onCompletion completion: (() -> Void)?)
}

extension SDImageCache: ImageCache {}

extension SDWebImageDownloader: ImageDownloader {}

class ImageRepository {

    public var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default {
        didSet {
            imageDownloader = SDWebImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    public static let shared = ImageRepository.init(withDownloader: SDWebImageDownloader.shared(), cache: SDImageCache.shared())

    let imageCache: ImageCache
    fileprivate(set) var imageDownloader: ImageDownloader

    var useDiskCache = true

    required init(withDownloader downloader: ImageDownloader, cache: ImageCache) {
        imageDownloader = downloader
        imageCache = cache
    }

    func resetImageCache() {
        imageCache.clearMemory()
        let semaphore = DispatchSemaphore(value: 1)
        imageCache.clearDisk {
            semaphore.signal()
        }
        let _ = semaphore.wait(timeout: .distantFuture)
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
