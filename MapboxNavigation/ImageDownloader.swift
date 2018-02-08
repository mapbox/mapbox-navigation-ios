import Foundation

typealias ImageDownloadCompletionBlock = (UIImage?, Data?, Error?, Bool) -> Void

protocol ReentrantImageDownloader {
    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) -> Void
    func setOperationClass(_ klass: AnyClass?)
}

class ImageDownloader: NSObject, ReentrantImageDownloader, URLSessionDataDelegate {
    private var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
    private var operationClass: AnyClass = ImageDownloadOperation.self

    private var queue: OperationQueue
    lazy private var urlSession: URLSession = {
        return URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()

    private var headers: [String: String] = ["Accept": "image/*;q=0.8"]

    private var operations: [URL: ImageDownload] = [:]

    private var dataTask: URLSessionDataTask?

    //TODO: placeholder/WIP
    private var data: [URL : Data] = [:]

    private var completions: [URL : ImageDownloadCompletionBlock] = [:]

    override init() {
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 6
        self.queue.name = "com.mapbox.navigation.ImageDownloader"
    }

    convenience init(sessionConfiguration: URLSessionConfiguration) {
        self.init()

        self.sessionConfiguration = sessionConfiguration
    }

    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) {
        let request: URLRequest = urlRequestWithURL(url)
//        let operation = ImageDownloadOperation.init(request: request, in: self.urlSession)
//        if completion != nil {
//            operation.addCompletion(completion!)
//        }
//        self.operations[url] = operation
//        self.queue.addOperation(operation)

        self.completions[url] = completion
        self.dataTask = urlSession.dataTask(with: request)
        self.dataTask?.resume()
    }

    private func urlRequestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers
        request.cachePolicy = .reloadIgnoringCacheData //We're using our own caching strategy. TODO: test?
        return request
    }

    func setOperationClass(_ klass: AnyClass?) {
        if let klass = klass {
            operationClass = klass
        } else {
            operationClass = ImageDownloadOperation.self
        }
    }

    // MARK: URLSessionDataDelegate
    // TODO: implement URLSessionDataDelegate callbacks to forward to operation for URL.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response: HTTPURLResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        if response.statusCode < 400 && response.statusCode != 304 {
            self.data[dataTask.originalRequest!.url!] = Data()
            completionHandler(.allow)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url else {
            return
        }
        if var localData: Data = self.data[url] {
            let bytes = [UInt8](data)
            localData.append(bytes, count: bytes.count)
            self.data[url] = localData
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error == nil else {
            NSLog("================> %@", String(describing: error))
            //TODO: wrap error (this is likely a client-side error)
//            completion(nil, nil, error, false)
            return
        }
        guard let url = task.originalRequest?.url else {
            NSLog("================> URL not found: \(String(describing: task.originalRequest))")
            //TODO: create an error object (this is likely never to be needed however)
//            completion(nil, nil, nil, false)
            return
        }
        if let completion: ImageDownloadCompletionBlock = completions[url], let data = self.data[url] {
            let image = UIImage.init(data: data)
            completion(image, data, error, true)
        }
    }


}
