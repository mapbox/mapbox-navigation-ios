import Foundation

protocol ImageDownload {
    init(request: URLRequest, in session: URLSession)
    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock)
}

class ImageDownloadOperation: Operation, ImageDownload, URLSessionDataDelegate {
    override var isConcurrent: Bool {
        return true
    }

    override var isFinished: Bool {
        return _finished
    }

    override var isExecuting: Bool {
        return _executing
    }

    private var request: URLRequest
    private var session: URLSession

    private var completionBlocks: Array<ImageDownloadCompletionBlock> = []

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

    private var dataTask: URLSessionDataTask?

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

}
