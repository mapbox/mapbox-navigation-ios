import Foundation

extension URL {
    public static func mapboxApiEndpoint() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.mapbox.com"
        return components.url!
    }
}
