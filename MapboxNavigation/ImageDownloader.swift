import Foundation

typealias ImageDownloadCompletionBlock = (UIImage?, Data?, Error?) -> Void

protocol ReentrantImageDownloader {
    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) -> Void
    func setOperationType(_ operationType: ImageDownload.Type?)
}

class ImageDownloader: NSObject, ReentrantImageDownloader, URLSessionDataDelegate {
    private var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
    private var operationType: ImageDownload.Type = ImageDownloadOperation.self

    private var queue: OperationQueue
    lazy private var urlSession: URLSession = {
        return URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()

    private var headers: [String: String] = ["Accept": "image/*;q=0.8"]

    private var operations: [URL: ImageDownload] = [:]

    override init() {
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 6
        self.queue.name = Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloader"
    }

    convenience init(sessionConfiguration: URLSessionConfiguration) {
        self.init()

        self.sessionConfiguration = sessionConfiguration
    }

    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) {
        let request: URLRequest = urlRequestWithURL(url)
        var operation: ImageDownload
        if operations[url] != nil {
            operation = operations[url]!
        } else {
            operation = operationType.init(request: request, in: self.urlSession)
            self.operations[url] = operation
            if let operation = operation as? Operation {
                self.queue.addOperation(operation)
            }
        }
        if let completion = completion {
            operation.addCompletion(completion)
        }
    }

    private func urlRequestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers
        request.cachePolicy = .reloadIgnoringCacheData
        return request
    }

    func setOperationType(_ operationType: ImageDownload.Type?) {
        if let operationType = operationType {
            self.operationType = operationType
        } else {
            self.operationType = ImageDownloadOperation.self
        }
    }

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response: HTTPURLResponse = response as? HTTPURLResponse, let url = response.url, let operation: ImageDownload = operations[url] else {
            completionHandler(.cancel)
            return
        }
        operation.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url, let operation: ImageDownload = operations[url] else {
            return
        }
        operation.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url, let operation: ImageDownload = operations[url] else {
            return
        }
        operation.urlSession?(session, task: task, didCompleteWithError: error)
        operations[url] = nil
    }

}
