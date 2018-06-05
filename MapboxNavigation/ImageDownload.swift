import Foundation

enum DownloadError: Error {
    case serverError
    case clientError
    case noImageData
}

protocol ImageDownload: URLSessionDataDelegate {
    init(request: URLRequest, in session: URLSession)
    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock)
    var isFinished: Bool { get }
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
    private let barrierQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloadCompletionBarrierQueue", attributes: .concurrent)

    required init(request: URLRequest, in session: URLSession) {
        self.request = request
        self.session = session
    }

    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock) {
        barrierQueue.async(flags: .barrier) {
            self.completionBlocks.append(completion)
        }
    }

    override func cancel() {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        super.cancel()

        if let dataTask = dataTask {
            dataTask.cancel()
            incomingData = nil
            self.dataTask = nil
        }

        if isExecuting {
            _executing = false
        }

        if !isFinished {
            _finished = true
        }

        barrierQueue.async {
            self.completionBlocks.removeAll()
        }
    }

    override func start() {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }

        if isCancelled == true {
            _finished = true
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

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response: HTTPURLResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        if response.statusCode < 400 {
            self.incomingData = Data()
            completionHandler(.allow)
        } else {
            fireAllCompletions(nil, data: nil, error: DownloadError.serverError)
            completionHandler(.cancel)
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
            fireAllCompletions(nil, data: nil, error: DownloadError.clientError)
            return
        }

        if let data = incomingData, let image = UIImage.init(data: data, scale: UIScreen.main.scale) {
            fireAllCompletions(image, data: data, error: nil)
        } else {
            fireAllCompletions(nil, data: incomingData, error: DownloadError.noImageData)
        }
        _finished = true
        _executing = false
        dataTask = nil
        barrierQueue.async {
            self.completionBlocks.removeAll()
        }
    }

    private func fireAllCompletions(_ image: UIImage?, data: Data?, error: Error?) {
        barrierQueue.sync {
            completionBlocks.forEach { $0(image, data, error) }
        }
    }
}
