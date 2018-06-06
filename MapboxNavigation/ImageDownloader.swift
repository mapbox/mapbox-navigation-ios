import Foundation

typealias ImageDownloadCompletionBlock = (UIImage?, Data?, Error?) -> Void

protocol ReentrantImageDownloader {
    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) -> Void
    func activeOperation(with url: URL) -> ImageDownload?
    func setOperationType(_ operationType: ImageDownload.Type?)
}

class ImageDownloader: NSObject, ReentrantImageDownloader, URLSessionDataDelegate {
    private var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default

    lazy private var urlSession: URLSession = {
        return URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()

    private var downloadQueue: OperationQueue
    private var accessQueue: DispatchQueue

    private var operationType: ImageDownload.Type = ImageDownloadOperation.self
    private var operations: [URL: ImageDownload] = [:]

    private var headers: [String: String] = ["Accept": "image/*;q=0.8"]

    override init() {
        self.downloadQueue = OperationQueue()
        self.downloadQueue.name = Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloader"
        self.accessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloaderInternal", attributes: .concurrent)
    }

    convenience init(sessionConfiguration: URLSessionConfiguration? = nil, operationType: ImageDownload.Type? = nil) {
        self.init()

        if let config = sessionConfiguration {
            self.sessionConfiguration = config
        }
        
        if let op = operationType {
            self.operationType = op
        }
    }

    deinit {
        self.downloadQueue.cancelAllOperations()
    }

    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) {
        accessQueue.sync(flags: .barrier) {
            let request: URLRequest = self.urlRequest(with: url)
            var operation: ImageDownload
            if let activeOperation = self.activeOperation(with: url) {
                operation = activeOperation
            } else {
                operation = self.operationType.init(request: request, in: self.urlSession)
                self.operations[url] = operation
                if let operation = operation as? Operation {
                    self.downloadQueue.addOperation(operation)
                }
            }
            if let completion = completion {
                operation.addCompletion(completion)
            }
        }
    }

    func activeOperation(with url: URL) -> ImageDownload? {
        var activeOperation: ImageDownload?

        if let operation = operations[url], !operation.isFinished {
            activeOperation = operation
        }

        return activeOperation
    }
    
    private func urlRequest(with url: URL) -> URLRequest {
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
        guard let response: HTTPURLResponse = response as? HTTPURLResponse, let url = response.url, let operation: ImageDownload = activeOperation(with: url) else {
            completionHandler(.cancel)
            return
        }
        operation.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url, let operation: ImageDownload = activeOperation(with: url) else {
            return
        }
        operation.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url, let operation: ImageDownload = activeOperation(with: url) else {
            return
        }
        operation.urlSession?(session, task: task, didCompleteWithError: error)
        accessQueue.async {
            self.operations[url] = nil
        }
    }

}
