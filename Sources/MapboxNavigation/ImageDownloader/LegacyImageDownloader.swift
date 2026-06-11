import Foundation

@available(iOS, deprecated: 13.0, message: "Use ImageDownloader instead.")
final class LegacyImageDownloader: ImageDownloaderProtocol {
    private let urlSession: URLSession

    init(configuration: URLSessionConfiguration? = nil) {
        let defaultConfiguration = URLSessionConfiguration.default
        // SpriteRepository owns sprite and shield persistence; avoid duplicate CFNetwork cache entries.
        defaultConfiguration.urlCache = nil
        defaultConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: configuration ?? defaultConfiguration)
    }

    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        urlSession.dataTask(with: URLRequest(url)) { data, response, error in
            if let response, let data {
                completion(.success(CachedURLResponse(response: response, data: data)))
            } else if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}
