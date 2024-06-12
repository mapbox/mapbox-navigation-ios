import _MapboxNavigationHelpers
import MapboxCommon_Private
import MapboxDirections
import MapboxNavigationNative
import MapboxNavigationNative_Private

/// RouterInterface from MapboxNavigationNative.
typealias RouterInterfaceNative = MapboxNavigationNative_Private.RouterInterface

struct RoutingProviderConfiguration: Sendable {
    var source: RoutingProviderSource
    var nativeHandlersFactory: NativeHandlersFactory
    var credentials: Credentials
}

/// Provides alternative access to routing API.
///
/// Use this class instead `Directions` requests wrapper to request new routes or refresh an existing one. Depending on
/// ``RoutingProviderSource``, ``MapboxRoutingProvider`` will use online and/or onboard routing engines. This may be
/// used when designing purely online or offline apps, or when you need to provide best possible service regardless of
/// internet collection.
public final class MapboxRoutingProvider: RoutingProvider, @unchecked Sendable {
    /// Initializes a new ``MapboxRoutingProvider``.
    init(with configuration: RoutingProviderConfiguration) {
        self.configuration = configuration
    }

    // MARK: Configuration

    let configuration: RoutingProviderConfiguration

    // MARK: Performing and Parsing Requests

    private lazy var router: RouterInterfaceNative = {
        let factory = configuration.nativeHandlersFactory
        return RouterFactory.build(
            for: configuration.source.nativeSource,
            cache: factory.cacheHandle,
            config: factory.configHandle(),
            historyRecorder: factory.historyRecorderHandle
        )
    }()

    struct ResponseDisposition: Decodable {
        var code: String?
        var message: String?
        var error: String?

        private enum CodingKeys: CodingKey {
            case code, message, error
        }
    }

    // MARK: Routes Calculation

    /// Begins asynchronously calculating routes using the given options and delivers the results to a closure.
    ///
    /// Depending on configured ``RoutingProviderSource``, this method may retrieve the routes asynchronously from the
    /// [Mapbox Directions API](https://www.mapbox.com/api-documentation/navigation/#directions) over a network
    /// connection or use onboard routing engine with available offline data.
    /// Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
    /// - Parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
    /// - Returns: Related request task. If, while waiting for the completion handler to execute, you no longer want the
    /// resulting routes, cancel corresponding task using this handle.
    public func calculateRoutes(options: RouteOptions) -> FetchTask {
        return Task { [
            sendableSelf = UncheckedSendable(self),
            sendableOptions = UncheckedSendable(options)
        ] in
            var result: Result<RouteResponse, DirectionsError>
            var origin: RouterOrigin
            (result, origin) = await sendableSelf.value.doRequest(options: sendableOptions.value)

            switch result {
            case .success(let routeResponse):
                guard let navigationRoutes = try? await NavigationRoutes(
                    routeResponse: routeResponse,
                    routeIndex: 0,
                    responseOrigin: origin
                ) else {
                    throw DirectionsError.unableToRoute
                }
                return navigationRoutes
            case .failure(let error):
                throw error
            }
        }
    }

    /// Begins asynchronously calculating matches using the given options and delivers the results to a closure.
    ///
    /// Depending on configured ``RoutingProviderSource``, this method may retrieve the matches asynchronously from the
    /// [Mapbox Map Matching API](https://docs.mapbox.com/api/navigation/#map-matching) over a network connection or use
    /// onboard routing engine with available offline data.
    /// - Parameter options: A `MatchOptions` object specifying the requirements for the resulting matches.
    /// - Returns: Related request task. If, while waiting for the completion handler to execute, you no longer want the
    /// resulting routes, cancel corresponding task using this handle.
    public func calculateRoutes(options: MatchOptions) -> FetchTask {
        return Task { [
            sendableSelf = UncheckedSendable(self),
            sendableOptions = UncheckedSendable(options)
        ] in
            var result: Result<MapMatchingResponse, DirectionsError>
            var origin: RouterOrigin
            (result, origin) = await sendableSelf.value.doRequest(options: sendableOptions.value)

            switch result {
            case .success(let routeResponse):
                guard let navigationRoutes = try? await NavigationRoutes(
                    routeResponse: RouteResponse(
                        matching: routeResponse,
                        options: options,
                        credentials: .init(sendableSelf.value.configuration.nativeHandlersFactory.apiConfiguration)
                    ),
                    routeIndex: 0,
                    responseOrigin: origin
                ) else {
                    throw DirectionsError.unableToRoute
                }
                return navigationRoutes
            case .failure(let error):
                throw error
            }
        }
    }

    private func doRequest<ResponseType: Codable>(options: DirectionsOptions) async -> (Result<
        ResponseType,
        DirectionsError
    >, RouterOrigin) {
        let directionsUri = Directions.url(forCalculating: options, credentials: configuration.credentials)
            .removingSKU().absoluteString
        let (result, origin) = await withCheckedContinuation { continuation in
            let routeSignature = GetRouteSignature(reason: .newRoute, origin: .platformSDK, comment: "")
            router.getRouteForDirectionsUri(
                directionsUri,
                options: GetRouteOptions(timeoutSeconds: nil),
                caller: routeSignature
            ) { (
                result: Expected<DataRef, NSArray>,
                origin: RouterOrigin
            ) in
                continuation.resume(returning: (result, origin))
            }
        }

        return await (
            parseResponse(
                userInfo: [
                    .options: options,
                    .credentials: Credentials(configuration.nativeHandlersFactory.apiConfiguration),
                ],
                result: result
            ),
            origin
        )
    }

    private func parseResponse<ResponseType: Codable>(
        userInfo: [CodingUserInfoKey: Any],
        result: Expected<DataRef, NSArray>
    ) async -> Result<ResponseType, DirectionsError> {
        guard let dataRef = result.value else {
            return .failure(.noData)
        }

        return parseResponse(
            userInfo: userInfo,
            result: dataRef.data,
            error: result.error as? Error
        )
    }

    private func parseResponse<ResponseType: Codable>(
        userInfo: [CodingUserInfoKey: Any],
        result: Expected<NSString, MapboxNavigationNative.RouterError>
    ) async -> Result<ResponseType, DirectionsError> {
        let json = result.value as String?
        guard let data = json?.data(using: .utf8) else {
            return .failure(.noData)
        }

        return parseResponse(
            userInfo: userInfo,
            result: data,
            error: result.error as? Error
        )
    }

    private func parseResponse<ResponseType: Codable>(
        userInfo: [CodingUserInfoKey: Any],
        result data: Data,
        error: Error?
    ) -> Result<ResponseType, DirectionsError> {
        do {
            let decoder = JSONDecoder()
            decoder.userInfo = userInfo

            guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                let apiError = DirectionsError(
                    code: nil,
                    message: nil,
                    response: nil,
                    underlyingError: error
                )
                return .failure(apiError)
            }

            guard (disposition.code == nil && disposition.message == nil) || disposition.code == "Ok" else {
                let apiError = DirectionsError(
                    code: disposition.code,
                    message: disposition.message,
                    response: nil,
                    underlyingError: error
                )
                return .failure(apiError)
            }

            let result = try decoder.decode(ResponseType.self, from: data)
            return .success(result)
        } catch {
            let bailError = DirectionsError(code: nil, message: nil, response: nil, underlyingError: error)
            return .failure(bailError)
        }
    }
}

extension ProfileIdentifier {
    var nativeProfile: RoutingProfile {
        let mode: RoutingMode = switch self {
        case .automobile:
            .driving
        case .automobileAvoidingTraffic:
            .drivingTraffic
        case .cycling:
            .cycling
        case .walking:
            .walking
        default:
            .driving
        }
        return RoutingProfile(mode: mode, account: "mapbox")
    }
}

extension URL {
    func removingSKU() -> URL {
        var urlComponents = URLComponents(string: absoluteString)!
        let filteredItems = urlComponents.queryItems?.filter { $0.name != "sku" }
        urlComponents.queryItems = filteredItems
        return urlComponents.url!
    }
}
