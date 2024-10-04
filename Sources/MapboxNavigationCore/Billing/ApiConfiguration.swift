import Foundation
import MapboxDirections

/// The Mapbox access token specified in the main application bundle’s Info.plist.
private let defaultAccessToken: String? =
    Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ??
    Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String ??
    UserDefaults.standard.string(forKey: "MBXAccessToken")

/// Configures access token for Mapbox API requests.
public struct ApiConfiguration: Sendable, Equatable {
    /// The default configuration. The SDK will attempt to find an access token from your app's `Info.plist`.
    public static var `default`: Self {
        guard let defaultAccessToken, !defaultAccessToken.isEmpty else {
            preconditionFailure(
                "A Mapbox access token is required. Go to <https://account.mapbox.com/access-tokens/>. In Info.plist, set the MBXAccessToken key to your access token."
            )
        }

        return .init(accessToken: defaultAccessToken, endPoint: .mapboxApiEndpoint())
    }

    /// A Mapbox [access token](https://www.mapbox.com/help/define-access-token/) used to authorize Mapbox API requests.
    public let accessToken: String
    /// An optional hostname to the server API. Defaults to `api.mapbox.com`.
    @_spi(MapboxInternal)
    public let endPoint: URL

    /// Initializes ``ApiConfiguration`` instance.
    /// - Parameters:
    ///   - accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/) used to authorize
    /// Mapbox API requests.
    public init(accessToken: String) {
        self.init(accessToken: accessToken, endPoint: nil)
    }

    /// Initializes ``ApiConfiguration`` instance.
    /// - Parameters:
    ///   - accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/) used to authorize
    /// Mapbox API requests.
    ///   - endPoint: An optional hostname to the server API.
    @_spi(MapboxInternal)
    public init(
        accessToken: String,
        endPoint: URL?
    ) {
        self.accessToken = accessToken
        self.endPoint = endPoint ?? .mapboxApiEndpoint()
    }

    init(requestURL url: URL) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let accessToken = components?
            .queryItems?
            .first { $0.name == .accessTokenUrlQueryItemName }?
            .value
        components?.path = ""
        components?.queryItems = nil
        self.init(
            accessToken: accessToken ?? defaultAccessToken!,
            endPoint: components?.url ?? .mapboxApiEndpoint()
        )
    }

    func accessTokenUrlQueryItem() -> URLQueryItem {
        .init(name: .accessTokenUrlQueryItemName, value: accessToken)
    }
}

extension Credentials {
    init(_ apiConfiguration: ApiConfiguration) {
        self.init(accessToken: apiConfiguration.accessToken, host: apiConfiguration.endPoint.absoluteURL)
    }
}

extension String {
    fileprivate static let accessTokenUrlQueryItemName: String = "access_token"
}
