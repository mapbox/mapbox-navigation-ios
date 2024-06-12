import UIKit

class ImageRepository {
    static let shared = ImageRepository()

    let imageCache: BimodalImageCache
    private(set) var imageDownloader: ImageDownloaderProtocol

    var useDiskCache: Bool

    required init(
        withDownloader downloader: ImageDownloaderProtocol? = nil,
        cache: BimodalImageCache? = nil,
        useDisk: Bool = true
    ) {
        self.imageDownloader = downloader ?? Self.defaultImageDownloader
        self.imageCache = cache ?? ImageCache()
        self.useDiskCache = useDisk
    }

    static let defaultImageDownloader: ImageDownloaderProtocol = ImageDownloader()

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

        imageDownloader.download(with: imageURL, completion: { [weak self] result in
            guard let strongSelf = self,
                  case .success(let cachedResponse) = result,
                  let image = UIImage(data: cachedResponse.data, scale: UIScreen.main.scale)
            else {
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
