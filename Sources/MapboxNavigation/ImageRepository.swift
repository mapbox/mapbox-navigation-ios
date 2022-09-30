import UIKit

class ImageRepository {
    public var sessionConfiguration: URLSessionConfiguration {
        didSet {
            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    public static let shared = ImageRepository.init()

    let imageCache: BimodalImageCache
    fileprivate(set) var imageDownloader: ReentrantImageDownloader
    private let requestTimeOut: TimeInterval = 10

    var useDiskCache: Bool

    required init(withDownloader downloader: ReentrantImageDownloader? = nil,
                  cache: BimodalImageCache? = nil,
                  useDisk: Bool = true) {
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = self.requestTimeOut
        imageDownloader = downloader ?? ImageDownloader(sessionConfiguration: sessionConfiguration)
        imageCache = cache ?? ImageCache()
        useDiskCache = useDisk
    }

    func resetImageCache(_ completion: CompletionHandler?) {
        imageCache.clearMemory()
        imageCache.clearDisk(completion: completion)
    }

    func storeImage(_ image: UIImage, forKey key: String, toDisk: Bool = true) {
        imageCache.store(image, forKey: key, toDisk: toDisk, completion: nil)
    }

    func cachedImageForKey(_ key: String) -> UIImage? {
        return imageCache.image(forKey: key)
    }

    func imageWithURL(_ imageURL: URL, cacheKey: String, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cachedImageForKey(cacheKey) {
            completion(cachedImage)
            return
        }

        let _ = imageDownloader.download(with: imageURL, completion: { [weak self] (cachedResponse, error) in
            guard let strongSelf = self,
                  let data = cachedResponse?.data,
                  let image = UIImage(data: data, scale: UIScreen.main.scale) else {
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
