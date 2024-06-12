import MapboxDirections
@testable import MapboxNavigationUIKit
import UIKit

final class ImageDownloaderSpy: ImageDownloaderProtocol {
    private var urlToCompletion = [URL: (Result<CachedURLResponse, Error>) -> Void]()

    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        urlToCompletion[url] = completion
    }

    func fireCompletion(for url: URL, result: Result<CachedURLResponse, Error>) {
        urlToCompletion[url]?(result)
    }
}
