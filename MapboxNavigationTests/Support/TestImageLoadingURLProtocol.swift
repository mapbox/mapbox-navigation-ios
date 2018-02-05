import UIKit

class TestImageLoadingURLProtocol: URLProtocol {

    private static var responseData: [URL : Data] = [:]
    private static var requests: [URL : URLRequest] = [:]

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
        // retrieve fake response (image) for request
        guard let data = TestImageLoadingURLProtocol.responseData[request.url!], let image: UIImage = UIImage(data: data), let client = client else {
            NSLog("========> No valid image data found for url: \(String(describing: request.url))")
            return
        }

        TestImageLoadingURLProtocol.requests[request.url!] = request

        // init an NSHTTPURLResponse
        let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        client.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: UIImagePNGRepresentation(image)!)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // ?
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
