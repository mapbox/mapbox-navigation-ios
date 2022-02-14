import UIKit
import XCTest

/**
 * This class stubs out the URL loading for any request url registered in `registerData(_, forURL:)` and records requests for a given URL for inspection. Note that unstubbed URLs will continue to load as normal.
 */
final class ImageLoadingURLProtocolSpy: URLProtocol {
    enum Error: Swift.Error {
        case httpStatus(Int)
        case other(Swift.Error)
    }

    private static let lock: NSLock = .init()
    private static var responseData: [URL: Result<Data, Error>] = [:]
    private static var activeRequests: [URL: URLRequest] = [:]
    private static var pastRequests: [URL: URLRequest] = [:]
    private static let imageLoadingSemaphore = DispatchSemaphore(value: 1)

    private var loadingStopped: Bool = false

    override static func canInit(with request: URLRequest) -> Bool {
        return withLock {
            responseData.keys.contains(request.url!)
        }
    }

    override static func canInit(with task: URLSessionTask) -> Bool {
        return withLock {
            let keys = responseData.keys
            return keys.contains(task.currentRequest!.url!) || keys.contains(task.originalRequest!.url!)
        }
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override static func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return a.url == b.url
    }

    override func startLoading() {
        ImageLoadingURLProtocolSpy.withLock {
            let request = self.request

            guard let url = request.url else {
                XCTFail("Somehow the request doesn't have a URL")
                return
            }

            guard let result = ImageLoadingURLProtocolSpy.responseData[url],
                  let client = client else {
                        XCTFail("No valid response data found for url: \(url)")
                        return
            }

            let urlLoadingBlock = {
                defer {
                    ImageLoadingURLProtocolSpy.withLock {
                        ImageLoadingURLProtocolSpy.pastRequests[url] = ImageLoadingURLProtocolSpy.activeRequests[url]
                        ImageLoadingURLProtocolSpy.activeRequests[url] = nil
                    }
                }

                XCTAssertFalse(self.loadingStopped, "URL Loading was previously stopped")

                // We only want there to be one active request per resource at any given time (with callbacks appended if requested multiple times)
                XCTAssertFalse(ImageLoadingURLProtocolSpy.hasActiveRequestForURL(url), "There should only be one request in flight at a time per resource")
                ImageLoadingURLProtocolSpy.withLock {
                    ImageLoadingURLProtocolSpy.activeRequests[url] = request
                }

                switch result {
                case .success(let imageData):
                    // send an NSHTTPURLResponse to the client
                    let response = HTTPURLResponse.init(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
                    client.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)

                    ImageLoadingURLProtocolSpy.imageLoadingSemaphore.wait()

                    client.urlProtocol(self, didLoad: imageData)
                case .failure(let error):
                    switch error {
                    case .other(let otherError):
                        client.urlProtocol(self, didFailWithError: otherError)
                    case .httpStatus(let statusCode):
                        // send an NSHTTPURLResponse to the client
                        let response = HTTPURLResponse.init(url: url, statusCode: statusCode, httpVersion: "1.1", headerFields: nil)
                        client.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
                    }
                }
                client.urlProtocolDidFinishLoading(self)

                ImageLoadingURLProtocolSpy.imageLoadingSemaphore.signal()
            }

            let defaultQueue = DispatchQueue.global(qos: .default)
            defaultQueue.async(execute: urlLoadingBlock)
        }
    }

    override func stopLoading() {
        loadingStopped = true
    }

    /**
     * Registers data for a given URL
     */
    static func registerData(_ data: Data, forURL url: URL) {
        withLock {
            responseData[url] = .success(data)
        }
    }

    static func registerError(_ error: Swift.Error, for url: URL) {
        withLock {
            responseData[url] = .failure(.other(error))
        }
    }

    static func registerHttpStatusCodeError(_ httpStatus: Int, for url: URL) {
        assert(httpStatus >= 400, "Only these status codes handled as errors")

        withLock {
            responseData[url] = .failure(.httpStatus(httpStatus))
        }
    }

    /**
     * Reset stubbed data, active and past requests
     */
    static func reset() {
        withLock {
            responseData = [:]
            activeRequests = [:]
            pastRequests = [:]
        }
    }

    /**
     * Indicates whether a request for the given URL is in progress
     */
    static func hasActiveRequestForURL(_ url: URL) -> Bool {
        return withLock {
            activeRequests.keys.contains(url)
        }
    }

    /**
     * Returns the most recently completed request for the given URL
     */
    static func pastRequestForURL(_ url: URL) -> URLRequest? {
        return withLock {
            pastRequests[url]
        }
    }

    /**
     * Pauses image loading once a request receives a response. Useful for testing re-entrant resource requests.
     */
    static func delayImageLoading() {
        ImageLoadingURLProtocolSpy.imageLoadingSemaphore.wait()
    }

    /**
     * Resumes image loading which was previously delayed due to `delayImageLoading()` having been called.
     */
    static func resumeImageLoading() {
        ImageLoadingURLProtocolSpy.imageLoadingSemaphore.signal()
    }

    private static func withLock<ReturnValue>(_ perform: () throws -> ReturnValue) rethrows -> ReturnValue {
        lock.lock(); defer {
            lock.unlock()
        }
        return try perform()
    }
}
