import Foundation
import MapboxDirections
import UIKit

typealias ImageDownloadCompletionBlock = (UIImage?, Data?, Error?) -> Void

protocol ReentrantImageDownloader {
    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) -> Void
    func activeOperation(with url: URL) -> ImageDownload?
    func setOperationType(_ operationType: ImageDownload.Type?)
}

class ImageDownloader: NSObject, ReentrantImageDownloader, URLSessionDataDelegate {
    private let sessionConfiguration: URLSessionConfiguration

    private var urlSession: URLSession!
    private let downloadQueue: OperationQueue
    private let accessQueue: DispatchQueue

    private var operationType: ImageDownload.Type
    private var operations: [URL: ImageDownload] = [:]

    private let headers: [String: String] = ["Accept": "image/*;q=0.8"]

    init(sessionConfiguration: URLSessionConfiguration = .default,
         operationType: ImageDownload.Type = ImageDownloadOperation.self) {
        self.sessionConfiguration = sessionConfiguration
        self.operationType = operationType

        self.downloadQueue = OperationQueue()
        self.downloadQueue.name = Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloader"
        self.accessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloaderInternal")
        super.init()

        // TODO: Write `URLSessionDelegate` proxy to break retain cycle between `Self` and `URLSession.delegate`.
        urlSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    deinit {
        self.downloadQueue.cancelAllOperations()
    }

    func downloadImage(with url: URL, completion: ImageDownloadCompletionBlock?) {
        accessQueue.sync {
            let request: URLRequest = self.urlRequest(with: url)
            var operation: ImageDownload
            if let activeOperation = self.unsafeActiveOperation(with: url) {
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
        return accessQueue.sync { unsafeActiveOperation(with: url) }
    }

    private func unsafeActiveOperation(with url: URL) -> ImageDownload? {
        guard let operation = operations[url], !operation.isFinished else {
            return nil
        }
        return operation
    }
    
    private func urlRequest(with url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers
        request.cachePolicy = .reloadIgnoringCacheData
        request.setValue(URLSession.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    func setOperationType(_ operationType: ImageDownload.Type?) {
        accessQueue.sync {
            if let operationType = operationType {
                self.operationType = operationType
            } else {
                self.operationType = ImageDownloadOperation.self
            }
        }
    }

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response: HTTPURLResponse = response as? HTTPURLResponse,
              let url = response.url,
              let operation: ImageDownload = activeOperation(with: url) else {
                  completionHandler(.cancel)
                  return
              }

        operation.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url,
              let operation: ImageDownload = activeOperation(with: url) else {
                  return
        }
        operation.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url,
              let operation: ImageDownload = activeOperation(with: url) else {
                  return
              }
        operation.urlSession?(session, task: task, didCompleteWithError: error)
        accessQueue.sync {
            self.operations[url] = nil
        }
    }
}
