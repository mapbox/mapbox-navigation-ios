import UIKit
import MapboxDirections
@testable import MapboxNavigation

final class ReentrantImageDownloaderSpy: ReentrantImageDownloader {
    var passedDownloadUrl: URL?
    var passedOperationType: ImageDownload.Type?
    var returnedDownloadResults = [URL: Data]()
    var returnedOperation: ImageDownload?

    func download(with url: URL, completion: CachedResponseCompletionHandler?) -> Void {
        passedDownloadUrl = url
        let response = cachedResponse(with: returnedDownloadResults[url], url: url)
        completion?(response, response == nil ? DirectionsError.noData : nil)
    }

    func activeOperation(with url: URL) -> ImageDownload? {
        return returnedOperation
    }

    func setOperationType(_ operationType: ImageDownload.Type?) {
        passedOperationType = operationType
    }

    private func cachedResponse(with data: Data?, url: URL) -> CachedURLResponse? {
        guard let data = data else { return nil }

        let response = URLResponse(url: url,
                                   mimeType: nil,
                                   expectedContentLength: data.count,
                                   textEncodingName: nil)
        return CachedURLResponse(response: response,
                                 data: data,
                                 storagePolicy: .allowed)
    }
}
