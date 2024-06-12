import Foundation

protocol ImageDownloaderProtocol {
    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void)
}
