import UIKit
import MapboxDirections
@testable import MapboxNavigation

final class ImageDownloaderSpy: ImageDownloaderProtocol {
    private var urlToCompletion = [URL: (Result<CachedURLResponse, Error>) -> Void]()

    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        urlToCompletion[url] = completion
    }

    func fireCompletion(for url: URL, result: Result<CachedURLResponse, Error>) {
        self.urlToCompletion[url]?(result)
    }
}
