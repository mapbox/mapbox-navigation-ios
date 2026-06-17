import Foundation

enum DownloadError: Error {
    case serverError
    case clientError
    case noImageData
}

actor ImageDownloader: ImageDownloaderProtocol {
    private let urlSession: URLSession

    private var inflightRequests: [URL: Task<CachedURLResponse, Error>] = [:]

    init(configuration: URLSessionConfiguration? = nil) {
        let defaultConfiguration = URLSessionConfiguration.default
        defaultConfiguration.urlCache = URLCache(memoryCapacity: 5 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024)
        self.urlSession = URLSession(configuration: configuration ?? defaultConfiguration)
    }

    nonisolated func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        Task {
            do {
                let response = try await self.fetch(url)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func fetch(_ url: URL) async throws -> CachedURLResponse {
        if let inflightTask = inflightRequests[url] {
            return try await inflightTask.value
        }

        let downloadTask = Task<CachedURLResponse, Error> {
            let (data, response) = try await urlSession.data(from: url)
            return CachedURLResponse(response: response, data: data)
        }

        inflightRequests[url] = downloadTask
        defer { inflightRequests[url] = nil }

        return try await downloadTask.value
    }
}
