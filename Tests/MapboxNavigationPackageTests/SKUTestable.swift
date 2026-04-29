#if DEBUG
import MapboxDirections
import MapboxMaps

extension URL {
    func queryItem(_ key: String) -> URLQueryItem? {
        let urlComponents = URLComponents(string: absoluteString)
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
