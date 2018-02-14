import UIKit
import XCTest

class TestImageLoadingURLProtocol: URLProtocol {

    private static var responseData: [URL: Data] = [:]
    private static var requests: [URL: URLRequest] = [:]

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
        guard let data = TestImageLoadingURLProtocol.responseData[url], let image: UIImage = UIImage(data: data), let client = client else {
            XCTFail("No valid image data found for url: \(url)")
            return
        }

        // We only want there to be one active request per resource at any given time (with callbacks appended if requested multiple times)
        if let _ = TestImageLoadingURLProtocol.requests[url] {
            XCTFail("There should only be one request in flight at a time per resource")
        } else {
            TestImageLoadingURLProtocol.requests[url] = request
        }

        // send an NSHTTPURLResponse to the client
        let response = HTTPURLResponse.init(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        client.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: UIImagePNGRepresentation(image)!)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        TestImageLoadingURLProtocol.requests[request.url!] = nil
    }

    class func registerData(_ data: Data, forURL url: URL) {
        responseData[url] = data
    }

    class func reset() {
        responseData = [:]
        requests = [:]
    }

    class func hasRequestForURL(_ url: URL) -> Bool {
        return requests.keys.contains(url)
    }
}
