import Foundation
import MapboxDirections
import UIKit

typealias CachedResponseCompletionHandler = (CachedURLResponse?, Error?) -> Void
typealias ImageDownloadCompletionHandler = (DownloadError?) -> Void

protocol ReentrantImageDownloader {
    func download(with url: URL, completion: CachedResponseCompletionHandler?) -> Void
    func activeOperation(with url: URL) -> ImageDownload?
    func setOperationType(_ operationType: ImageDownload.Type?)
}

class ImageDownloader: NSObject, ReentrantImageDownloader, URLSessionDataDelegate {
    private let sessionConfiguration: URLSessionConfiguration

    private let urlSession: URLSession
    private let downloadQueue: OperationQueue
    private let accessQueue: DispatchQueue

    private var operationType: ImageDownload.Type
    private var operations: [URL: ImageDownload] = [:]

    init(sessionConfiguration: URLSessionConfiguration = .default,
         operationType: ImageDownload.Type = ImageDownloadOperation.self) {
        self.sessionConfiguration = sessionConfiguration
        self.operationType = operationType

        self.downloadQueue = OperationQueue()
        self.downloadQueue.name = Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloader"
        self.accessQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".ImageDownloaderInternal")

        let urlSessionDelegateProxy = URLSessionDelegateProxy()
        urlSession = URLSession(configuration: sessionConfiguration, delegate: urlSessionDelegateProxy, delegateQueue: nil)
        super.init()

        urlSessionDelegateProxy.delegate = self
    }

    deinit {
        self.downloadQueue.cancelAllOperations()
        urlSession.invalidateAndCancel()
    }

    func download(with url: URL, completion: CachedResponseCompletionHandler?) {
        accessQueue.sync {
            let request = URLRequest(url)
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
