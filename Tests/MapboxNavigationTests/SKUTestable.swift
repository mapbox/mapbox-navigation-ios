#if DEBUG
import MapboxMaps
import MapboxSpeech
import MapboxDirections
import OHHTTPStubs

extension MapView {
    
    class var skuToken: String? {
        let sema = DispatchSemaphore(value: 0)
        var token: String?
        
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            let isMapboxStyleURL = request.url?.isMapboxStyleURL ?? false
            guard isMapboxStyleURL else { return true }
            token = request.url?.queryItem("sku")?.value
            sema.signal()
            return true
        }) { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 200, headers: [:])
        }
        _ = MapView(frame: CGRect(origin: .zero, size: CGSize(width: 64, height: 64)))
        
        _ = sema.wait(timeout: .now() + 2)
        
        HTTPStubs.removeAllStubs()
        
        return token
    }
}

extension SpeechSynthesizer {
    @objc var skuToken: String? {
        let options = SpeechOptions(text: "foo")
        let url = self.url(forSynthesizing: options)
        return url.queryItem("sku")?.value
    }
}

extension Directions {    
    @objc var skuToken: String? {
        let options = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 1, longitude: 2),
            CLLocationCoordinate2D(latitude: 3, longitude: 4)
        ])
        let url = self.url(forCalculating: options)
        return url.queryItem("sku")?.value
    }
}

extension URL {
    func queryItem(_ key: String) -> URLQueryItem? {
        let urlComponents = URLComponents(string: self.absoluteString)
        return urlComponents?.queryItems?.filter { $0.name == key }.first
    }
    
    var isMapboxAPIURL: Bool {
        guard let urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return false }
        guard let host = urlComponents.host else { return false }
        guard host.contains("api.mapbox.com") else { return false }
        
        return true
    }
    
    var isMapboxStyleURL: Bool {
        guard let urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return false }
        guard let host = urlComponents.host else { return false }
        guard host.contains("api.mapbox.com") else { return false }
        guard urlComponents.path.contains("styles") else { return false }
        
        return true
    }
}
#endif
