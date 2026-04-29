import MapboxDirections
@testable import MapboxNavigationUIKit
import UIKit

final class ReentrantImageDownloaderSpy: ImageDownloaderProtocol {
    var passedDownloadUrl: URL?
    var returnedDownloadResults = [URL: Data]()

    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        passedDownloadUrl = url
        let response = cachedResponse(with: returnedDownloadResults[url], url: url)
        if let response {
            completion(.success(response))
        } else {
            completion(.failure(DirectionsError.noData))
        }
    }

    private func cachedResponse(with data: Data?, url: URL) -> CachedURLResponse? {
        guard let data else { return nil }

        let response = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        return CachedURLResponse(
            response: response,
            data: data,
            storagePolicy: .allowed
        )
    }
}
