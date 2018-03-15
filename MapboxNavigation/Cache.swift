import Foundation

typealias CompletionHandler = () -> Void

/**
 A cache consists of both in-memory and on-disk components, both of which can be reset.
 */
protocol BimodalCache {
    func clearMemory()
    func clearDisk(completion: CompletionHandler?)
}

/**
 A cache which supports storing images
 */
protocol BimodalImageCache: BimodalCache {
    func store(_ image: UIImage, forKey key: String, toDisk: Bool, completion completionBlock: CompletionHandler?)
    func imageFromCache(forKey: String?) -> UIImage?
}

/**
 A cache which supports storing data
 */
protocol BimodalDataCache: BimodalCache {
    func store(_ data: Data, forKey key: String, toDisk: Bool, completion completionBlock: CompletionHandler?)
    func dataFromCache(forKey: String?) -> Data?
}
