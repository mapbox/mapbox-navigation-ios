import Foundation

extension URLRequest {
    init(_ requestURL: URL) {
        let headers: [String: String] = ["Accept": "image/*;q=0.8"]
        self = URLRequest(url: requestURL)
        self.allHTTPHeaderFields = headers
        self.cachePolicy = .reloadIgnoringCacheData
        self.setValue(URLSession.userAgent, forHTTPHeaderField: "User-Agent")
    }
}
