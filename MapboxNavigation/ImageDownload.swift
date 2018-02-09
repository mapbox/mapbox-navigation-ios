import Foundation

protocol ImageDownload: URLSessionDataDelegate {
    init(request: URLRequest, in session: URLSession)
    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock)
}

class ImageDownloadOperation: Operation, ImageDownload {
    override var isConcurrent: Bool {
        return true
    }

    override var isFinished: Bool {
        return _finished
    }

    override var isExecuting: Bool {
        return _executing
    }

    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var request: URLRequest
    private var session: URLSession

    private var dataTask: URLSessionDataTask?
    private var incomingData: Data?
    private var completionBlocks: Array<ImageDownloadCompletionBlock> = []

    required init(request: URLRequest, in session: URLSession) {
        self.request = request
        self.session = session
    }

    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock) {
        completionBlocks.append(completion)
    }

    override func cancel() {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        super.cancel()

        if let dataTask = dataTask {
            dataTask.cancel()
            self.dataTask = nil
        }

        if isExecuting {
            _executing = false
        }

        if !isFinished {
            _finished = true
        }

        // drop any image data?
        // drop any callbacks?
        // or are we disposed of at this point?
    }

    override func start() {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }

        if isCancelled == true {
            _finished = true
            // reset?
            return
        }

        dataTask = session.dataTask(with: self.request)
        if let dataTask = dataTask {
            _executing = true
            dataTask.resume()
        } else {
            //fail and bail; connection failed or bad URL (client-side error)
        }

    }

    //TODO: ensure completion block(s) is/are called on main queue

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response: HTTPURLResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        if response.statusCode < 400 && response.statusCode != 304 {
            self.incomingData = Data()
            completionHandler(.allow)
        } else {
            //TODO: sad path handling
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if var localData: Data = self.incomingData {
            let bytes = [UInt8](data)
            localData.append(bytes, count: bytes.count)
            self.incomingData = localData
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error == nil else {
            NSLog("================> %@", String(describing: error))
            //TODO: wrap error (this is likely a client-side error)
            //            completion(nil, nil, error, false)
            return
        }

        if let data = incomingData, let image = UIImage.init(data: data) {
            for completion in completionBlocks {
                completion(image, data, error, true)
            }
        } else {
            // data was not an image. Create or wrap inbound error.
        }

    }

}
