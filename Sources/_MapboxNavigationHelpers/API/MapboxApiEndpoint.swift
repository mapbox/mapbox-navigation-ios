import Foundation

extension URL {
    public static func mapboxApiEndpoint() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.mapbox.com"
        return components.url!
    }

    /// Whether the URL has the scheme and host of ``mapboxApiEndpoint()``.
    public var isMapboxApiEndpoint: Bool {
        let endpoint = URL.mapboxApiEndpoint()
        return scheme?.lowercased() == endpoint.scheme && host?.lowercased() == endpoint.host
    }

    /// Returns the URL with its `access_token` query item set to `accessToken`.
    ///
    /// The URL is returned unchanged when it is not a ``isMapboxApiEndpoint`` URL or when `accessToken` is empty,
    /// so the token is never sent to another host, for example when the URL comes from an API response.
    public func addingMapboxAccessToken(_ accessToken: String) -> URL {
        guard isMapboxApiEndpoint,
              !accessToken.isEmpty,
              let encodedAccessToken = accessToken.addingPercentEncoding(withAllowedCharacters: .queryValueAllowed),
              var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        else {
            return self
        }

        // Percent-encoded items keep the existing query byte-for-byte; decoding and re-encoding would turn `%2B` into
        // `+`, which servers read as a space.
        var queryItems = components.percentEncodedQueryItems ?? []
        queryItems.removeAll { $0.name == "access_token" }
        queryItems.append(URLQueryItem(name: "access_token", value: encodedAccessToken))
        components.percentEncodedQueryItems = queryItems
        return components.url ?? self
    }
}

extension CharacterSet {
    fileprivate static let queryValueAllowed = CharacterSet.urlQueryAllowed
        .subtracting(CharacterSet(charactersIn: "&=+#"))
}
