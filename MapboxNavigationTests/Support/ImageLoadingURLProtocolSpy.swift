import UIKit
import XCTest

/**
 * This class stubs out the URL loading for any request url registered in `registerData(_, forURL:)` and records requests for a given URL for inspection. Note that unstubbed URLs will continue to load as normal.
 */
class ImageLoadingURLProtocolSpy: URLProtocol {

    private static var responseData: [URL: Data] = [:]
    private static var activeRequests: [URL: URLRequest] = [:]
    private static var pastRequests: [URL: URLRequest] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        return responseData.keys.contains(request.url!)
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        let keys = responseData.keys
        return keys.contains(task.currentRequest!.url!) || keys.contains(task.originalRequest!.url!)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return a.url == b.url
    }

    override func startLoading() {
        guard let url = request.url else {
            XCTFail("Somehow the request doesn't have a URL")
            return
        }

        // retrieve fake response (image) for request; ensure it is an image
        guard let data = ImageLoadingURLProtocolSpy.responseData[url], let image: UIImage = UIImage(data: data), let client = client else {
            XCTFail("No valid image data found for url: \(url)")
            return
        }

        defer {
            ImageLoadingURLProtocolSpy.pastRequests[url] = ImageLoadingURLProtocolSpy.activeRequests[url]
            ImageLoadingURLProtocolSpy.activeRequests[url] = nil
        }

        // We only want there to be one active request per resource at any given time (with callbacks appended if requested multiple times)
        if ImageLoadingURLProtocolSpy.hasActiveRequestForURL(url) {
            XCTFail("There should only be one request in flight at a time per resource")
        } else {
            ImageLoadingURLProtocolSpy.activeRequests[url] = request
        }

        // send an NSHTTPURLResponse to the client
        let response = HTTPURLResponse.init(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        client.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: UIImagePNGRepresentation(image)!)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }

    /**
     * Registers data for a given URL
     */
    class func registerData(_ data: Data, forURL url: URL) {
        responseData[url] = data
    }

    /**
     * Reset stubbed data, active and past requests
     */
    class func reset() {
        responseData = [:]
        activeRequests = [:]
        pastRequests = [:]
    }

    /**
     * Indicates whether a request for the given URL is in progress
     */
    class func hasActiveRequestForURL(_ url: URL) -> Bool {
        return activeRequests.keys.contains(url)
    }

    /**
     * Returns the most recently completed request for the given URL
     */
    class func pastRequestForURL(_ url: URL) -> URLRequest? {
        return pastRequests[url]
    }
}
