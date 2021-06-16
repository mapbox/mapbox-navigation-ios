import UIKit

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

final class ImageDownloadOperation: Operation, ImageDownload {
    @objc(ImageDownloadOperationState)
    private enum State: Int {
        case ready
        case executing
        case finished
    }

    private let stateLock: NSLock = .init()
    private var _state: State = .ready

    @objc
    private dynamic var state: State {
        get {
            stateLock.lock(); defer {
                stateLock.unlock()
            }
            return _state
        }
        set {
            willChangeValue(forKey: #keyPath(state))
            stateLock.lock()
            _state = newValue
            stateLock.unlock()
            didChangeValue(forKey: #keyPath(state))
        }
    }

    final override var isReady: Bool {
        return state == .ready && super.isReady
    }

    final override var isExecuting: Bool {
        return state == .executing
    }

    final override var isFinished: Bool {
        return state == .finished
    }

    override var isConcurrent: Bool {
        return true
    }

    // MARK: - NSObject

    @objc
    private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return [#keyPath(state)]
    }

    @objc
    private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return [#keyPath(state)]
    }

    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return [#keyPath(state)]
    }

    private let request: URLRequest
    private let session: URLSession

    private var dataTask: URLSessionDataTask?
    private var incomingData: Data?
    private var completionBlocks: [ImageDownloadCompletionBlock] = .init()
    private let lock: NSLock = .init()

    required init(request: URLRequest, in session: URLSession) {
        self.request = request
        self.session = session
    }

    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock) {
        withLock {
            completionBlocks.append(completion)
        }
    }

    override func cancel() {
        withLock {
            super.cancel()
            if let dataTask = dataTask {
                dataTask.cancel()
                incomingData = nil
                self.dataTask = nil
            }
            state = .finished
        }
    }

    override func start() {
        withLock {
            guard !isCancelled && state != .finished else {
                state = .finished;
                return
            }

            state = .executing
            let dataTask = session.dataTask(with: self.request)
            dataTask.resume()

            self.dataTask = dataTask
        }
    }

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response: HTTPURLResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        if response.statusCode < 400 {
            withLock {
                incomingData = Data()
            }
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        withLock {
            incomingData?.append(data)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let (incomingData, completions) = withLock { () -> (Data?, [ImageDownloadCompletionBlock]) in
            let returnData = (self.incomingData, self.completionBlocks)
            self.completionBlocks.removeAll()
            return returnData
        }

        let completionData: (UIImage?, Data?, Error?)

        if error != nil {
            if let urlResponse = task.response as? HTTPURLResponse,
               urlResponse.statusCode >= 400 {
                completionData = (nil, nil, DownloadError.serverError)

            }
            else {
                completionData = (nil, nil, DownloadError.clientError)
            }
        }
        else {
            if let data = incomingData {
                if let image = UIImage(data: data, scale: UIScreen.main.scale) {
                    completionData = (image, data,  nil)
                }
                else {
                    completionData = (nil, data,  nil)
                }
            }
            else {
                completionData = (nil, nil,  nil)
            }
        }

        // The motivation is to call completions outside the lock to reduce the likehood of a deadlock.
        for completion in completions {
            completion(completionData.0, completionData.1, completionData.2)
        }

        withLock {
            dataTask = nil
        }
        state = .finished
    }

    private func withLock<ReturnValue>(_ perform: () throws -> ReturnValue) rethrows -> ReturnValue {
        lock.lock(); defer {
            lock.unlock()
        }
        return try perform()
    }
}
