import MapboxDirections

/// Allows to configure access token and endpoint for separate SDK requests separately for directions, maps, and speech
/// requests.
public struct NavigationCoreApiConfiguration: Equatable, Sendable {
    /// The configuration used to make directions-related requests.
    public let navigation: ApiConfiguration
    /// The configuration used to make map-loading requests.
    public let map: ApiConfiguration
    /// The configuration used to make speech-related requests.
    public let speech: ApiConfiguration

    /// Initializes ``NavigationCoreApiConfiguration`` instance.
    /// - Parameters:
    ///   - navigation: The configuration used to make directions-related requests.
    ///   - map: The configuration used to make map-loading requests.
    ///   - speech: The configuration used to make speech-related requests.
    public init(
        navigation: ApiConfiguration = .default,
        map: ApiConfiguration = .default,
        speech: ApiConfiguration = .default
    ) {
        self.navigation = navigation
        self.map = map
        self.speech = speech
    }
}

extension NavigationCoreApiConfiguration {
    /// Initializes ``NavigationCoreApiConfiguration`` instance.
    /// - Parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/) used to
    /// authorize Mapbox API requests.
    public init(accessToken: String) {
        let configuration = ApiConfiguration(accessToken: accessToken)
        self.init(
            navigation: configuration,
            map: configuration,
            speech: configuration
        )
    }
}
