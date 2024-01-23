import Foundation

@available(iOS, deprecated: 13.0, message: "Use ImageDownloader instead.")
final class LegacyImageDownloader: ImageDownloaderProtocol {
    private let urlSession: URLSession

    init(configuration: URLSessionConfiguration? = nil) {
        let defaultConfiguration = URLSessionConfiguration.default
        defaultConfiguration.urlCache = URLCache(memoryCapacity: 5 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
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
