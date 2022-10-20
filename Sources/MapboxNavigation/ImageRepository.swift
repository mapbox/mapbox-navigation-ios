import UIKit
import MapboxCommon

class ImageRepository {
    public var sessionConfiguration: URLSessionConfiguration {
        didSet {
//            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    public static let shared = ImageRepository.init()

//    let imageCache: BimodalImageCache
//    fileprivate(set) var imageDownloader: ReentrantImageDownloader
    let cache: any BimodalURLCaching
    private let requestTimeOut: TimeInterval = 10

    var useDiskCache: Bool

    required init(//withDownloader downloader: ReentrantImageDownloader? = nil,
        cache: (any BimodalURLCaching)? = nil,
        useDisk: Bool = true) {
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = self.requestTimeOut
//        imageDownloader = downloader ?? ImageDownloader(sessionConfiguration: sessionConfiguration)
                      self.cache = cache ?? BimodalTileStoreCaching(tileStore: TileStoreCaching(tileStore: TileStore.default),
                                                                    memoryCache: ImageCache())//ImageCache()
        useDiskCache = useDisk
    }

    func resetImageCache(_ completion: CompletionHandler?) {
        cache.clearCache(completion: completion)
//        imageCache.clearMemory()
//        imageCache.clearDisk(completion: completion)
    }

    func storeImage(_ image: UIImage, forKey key: String, toDisk: Bool = true) {
//        imageCache.store(image, forKey: key, toDisk: toDisk, completion: nil)
        guard let data = image.pngData() else { return }
        cache.store(data,
                    forKey: key,
                    policy: toDisk ? .diskOnly : .memoryAndDisk,
                    completion: nil)
    }

    func cachedImageForKey(_ key: String) -> UIImage? {
//        return imageCache.image(forKey: key)
        return cache.dataFromCache(forKey: key).flatMap { UIImage(data: $0) }
    }

    func imageWithURL(_ imageURL: URL, cacheKey: String, completion: @escaping (UIImage?) -> Void) {
        cache.storeResource(fromURL: imageURL,
                            policy: .memoryAndDisk,
                            completion: { data in
            completion(data.flatMap { UIImage(data: $0) })
        })
//        if let cachedImage = cachedImageForKey(cacheKey) {
//            completion(cachedImage)
//            return
//        }
//
//        let _ = imageDownloader.download(with: imageURL, completion: { [weak self] (cachedResponse, error) in
//            guard let strongSelf = self,
//                  let data = cachedResponse?.data,
//                  let image = UIImage(data: data, scale: UIScreen.main.scale) else {
//                completion(nil)
//                return
//            }
//
//            guard error == nil else {
//                completion(image)
//                return
//            }
//
//            strongSelf.imageCache.store(image, forKey: cacheKey, toDisk: strongSelf.useDiskCache, completion: {
//                completion(image)
//            })
//        })
    }

    func disableDiskCache() {
        useDiskCache = false
    }
}
