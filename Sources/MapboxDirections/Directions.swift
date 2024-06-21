import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

typealias JSONDictionary = [String: Any]

/// Indicates that an error occurred in MapboxDirections.
public let MBDirectionsErrorDomain = "com.mapbox.directions.ErrorDomain"

/// A `Directions` object provides you with optimal directions between different locations, or waypoints. The directions
/// object passes your request to the [Mapbox Directions API](https://docs.mapbox.com/api/navigation/#directions) and
/// returns the requested information to a closure (block) that you provide. A directions object can handle multiple
/// simultaneous requests. A ``RouteOptions`` object specifies criteria for the results, such as intermediate waypoints,
/// a mode of transportation, or the level of detail to be returned.
///
/// Each result produced by the directions object is stored in a ``Route`` object. Depending on the ``RouteOptions``
/// object you provide, each route may include detailed information suitable for turn-by-turn directions, or it may
/// include only high-level information such as the distance, estimated travel time, and name of each leg of the trip.
/// The waypoints that form the request may be conflated with nearby locations, as appropriate; the resulting waypoints
/// are provided to the closure.
@_documentation(visibility: internal)
open class Directions: @unchecked Sendable {
    /// A closure (block) to be called when a directions request is complete.
    ///
    /// - Parameter result: A `Result` enum that represents the ``RouteResponse`` if the request returned successfully,
    /// or the error if it did not.
    public typealias RouteCompletionHandler = @Sendable (
        _ result: Result<RouteResponse, DirectionsError>
    ) -> Void

    /// A closure (block) to be called when a map matching request is complete.
    ///
    /// - Parameter result: A `Result` enum that represents the ``MapMatchingResponse`` if the request returned
    /// successfully, or the error if it did not.
    public typealias MatchCompletionHandler = @Sendable (
        _ result: Result<MapMatchingResponse, DirectionsError>
    ) -> Void

    /// A closure (block) to be called when a directions refresh request is complete.
    ///
    ///  - parameter credentials: An object containing the credentials used to make the request.
    ///  - parameter result: A `Result` enum that represents the ``RouteRefreshResponse`` if the request returned
    /// successfully, or the error if it did not.
    public typealias RouteRefreshCompletionHandler = @Sendable (
        _ credentials: Credentials,
        _ result: Result<RouteRefreshResponse, DirectionsError>
    ) -> Void

    // MARK: Creating a Directions Object

    /// The shared directions object.
    ///
    /// To use this object, a Mapbox [access token](https://docs.mapbox.com/help/glossary/access-token/) should be
    /// specified in the `MBXAccessToken` key in the main application bundle’s Info.plist.
    public static let shared: Directions = .init()

    /// The Authorization & Authentication credentials that are used for this service.
    ///
    /// If nothing is provided, the default behavior is to read credential values from the developer's Info.plist.
    public let credentials: Credentials

    private let urlSession: URLSession
    private let processingQueue: DispatchQueue

    /// Creates a new instance of Directions object.
    /// - Parameters:
    ///    - credentials: Credentials that will be used to make API requests to Mapbox Directions API.
    ///    - urlSession: URLSession that will be used to submit API requests to Mapbox Directions API.
    ///    - processingQueue: A DispatchQueue that will be used for CPU intensive work.
    public init(
        credentials: Credentials = .init(),
        urlSession: URLSession = .shared,
        processingQueue: DispatchQueue = .global(qos: .userInitiated)
    ) {
        self.credentials = credentials
        self.urlSession = urlSession
        self.processingQueue = processingQueue
    }

    // MARK: Getting Directions

    /// Begins asynchronously calculating routes using the given options and delivers the results to a closure.
    ///
    /// This method retrieves the routes asynchronously from the [Mapbox Directions
    /// API](https://www.mapbox.com/api-documentation/navigation/#directions) over a network connection. If a connection
    /// error or server error occurs, details about the error are passed into the given completion handler in lieu of
    /// the routes.
    ///
    /// Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
    /// - Parameters:
    ///   - options: A ``RouteOptions`` object specifying the requirements for the resulting routes.
    ///   - completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the
    /// application’s main thread.
    /// - Returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to
    /// execute, you no longer want the resulting routes, cancel this task.
    @discardableResult
    open func calculate(
        _ options: RouteOptions,
        completionHandler: @escaping RouteCompletionHandler
    ) -> URLSessionDataTask {
        options.fetchStartDate = Date()
        let request = urlRequest(forCalculating: options)
        let requestTask = urlSession.dataTask(with: request) { possibleData, possibleResponse, possibleError in

            if let urlError = possibleError as? URLError {
                completionHandler(.failure(.network(urlError)))
                return
            }

            guard let response = possibleResponse, ["application/json", "text/html"].contains(response.mimeType) else {
                completionHandler(.failure(.invalidResponse(possibleResponse)))
                return
            }

            guard let data = possibleData else {
                completionHandler(.failure(.noData))
                return
            }

            self.processingQueue.async {
                do {
                    let decoder = JSONDecoder()
                    decoder.userInfo = [
                        .options: options,
                        .credentials: self.credentials,
                    ]

                    guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                        let apiError = DirectionsError(
                            code: nil,
                            message: nil,
                            response: possibleResponse,
                            underlyingError: possibleError
                        )
                        completionHandler(.failure(apiError))
                        return
                    }

                    guard (disposition.code == nil && disposition.message == nil) || disposition.code == "Ok" else {
                        let apiError = DirectionsError(
                            code: disposition.code,
                            message: disposition.message,
                            response: response,
                            underlyingError: possibleError
                        )
                        completionHandler(.failure(apiError))
                        return
                    }

                    let result = try decoder.decode(RouteResponse.self, from: data)
                    guard result.routes != nil else {
                        completionHandler(.failure(.unableToRoute))
                        return
                    }

                    completionHandler(.success(result))
                } catch {
                    let bailError = DirectionsError(code: nil, message: nil, response: response, underlyingError: error)
                    completionHandler(.failure(bailError))
                }
            }
        }
        requestTask.priority = 1
        requestTask.resume()

        return requestTask
    }

    /// Begins asynchronously calculating matches using the given options and delivers the results to a closure.This
    /// method retrieves the matches asynchronously from the [Mapbox Map Matching
    /// API](https://docs.mapbox.com/api/navigation/#map-matching) over a network connection. If a connection error or
    /// server error occurs, details about the error are passed into the given completion handler in lieu of the routes.
    ///
    ///  To get ``Route``s based on these matches, use the `calculateRoutes(matching:completionHandler:)` method
    /// instead.
    /// - Parameters:
    ///   - options: A ``MatchOptions`` object specifying the requirements for the resulting matches.
    ///   - completionHandler: The closure (block) to call with the resulting matches. This closure is executed on the
    /// application’s main thread.
    /// - Returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to
    /// execute, you no longer want the resulting matches, cancel this task.
    @discardableResult
    open func calculate(
        _ options: MatchOptions,
        completionHandler: @escaping MatchCompletionHandler
    ) -> URLSessionDataTask {
        options.fetchStartDate = Date()
        let request = urlRequest(forCalculating: options)
        let requestTask = urlSession.dataTask(with: request) { possibleData, possibleResponse, possibleError in
            if let urlError = possibleError as? URLError {
                completionHandler(.failure(.network(urlError)))
                return
            }

            guard let response = possibleResponse, response.mimeType == "application/json" else {
                completionHandler(.failure(.invalidResponse(possibleResponse)))
                return
            }

            guard let data = possibleData else {
                completionHandler(.failure(.noData))
                return
            }

            self.processingQueue.async {
                do {
                    let decoder = JSONDecoder()
                    decoder.userInfo = [
                        .options: options,
                        .credentials: self.credentials,
                    ]
                    guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                        let apiError = DirectionsError(
                            code: nil,
                            message: nil,
                            response: possibleResponse,
                            underlyingError: possibleError
                        )
                        completionHandler(.failure(apiError))
                        return
                    }

                    guard disposition.code == "Ok" else {
                        let apiError = DirectionsError(
                            code: disposition.code,
                            message: disposition.message,
                            response: response,
                            underlyingError: possibleError
                        )
                        completionHandler(.failure(apiError))
                        return
                    }

                    let response = try decoder.decode(MapMatchingResponse.self, from: data)

                    guard response.matches != nil else {
                        completionHandler(.failure(.unableToRoute))
                        return
                    }

                    completionHandler(.success(response))
                } catch {
                    let caughtError = DirectionsError.unknown(
                        response: response,
                        underlying: error,
                        code: nil,
                        message: nil
                    )
                    completionHandler(.failure(caughtError))
                }
            }
        }
        requestTask.priority = 1
        requestTask.resume()

        return requestTask
    }

    /// Begins asynchronously calculating routes that match the given options and delivers the results to a closure.
    ///
    /// This method retrieves the routes asynchronously from the [Mapbox Map Matching
    /// API](https://docs.mapbox.com/api/navigation/#map-matching) over a network connection. If a connection error or
    /// server error occurs, details about the error are passed into the given completion handler in lieu of the routes.
    ///
    /// To get the ``Match``es that these routes are based on, use the `calculate(_:completionHandler:)` method instead.
    /// - Parameters:
    ///   - options: A ``MatchOptions`` object specifying the requirements for the resulting match.
    ///   - completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the
    /// application’s main thread.
    /// - Returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to
    /// execute, you no longer want the resulting routes, cancel this task.
    @discardableResult
    open func calculateRoutes(
        matching options: MatchOptions,
        completionHandler: @escaping RouteCompletionHandler
    ) -> URLSessionDataTask {
        options.fetchStartDate = Date()
        let request = urlRequest(forCalculating: options)
        let requestTask = urlSession.dataTask(with: request) { possibleData, possibleResponse, possibleError in
            if let urlError = possibleError as? URLError {
                completionHandler(.failure(.network(urlError)))
                return
            }

            guard let response = possibleResponse, ["application/json", "text/html"].contains(response.mimeType) else {
                completionHandler(.failure(.invalidResponse(possibleResponse)))
                return
            }

            guard let data = possibleData else {
                completionHandler(.failure(.noData))
                return
            }

            self.processingQueue.async {
                do {
                    let decoder = JSONDecoder()
                    decoder.userInfo = [
                        .options: options,
                        .credentials: self.credentials,
                    ]

                    guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                        let apiError = DirectionsError(
                            code: nil,
                            message: nil,
                            response: possibleResponse,
                            underlyingError: possibleError
                        )
                        completionHandler(.failure(apiError))
                        return
                    }

                    guard disposition.code == "Ok" else {
                        let apiError = DirectionsError(
                            code: disposition.code,
                            message: disposition.message,
                            response: response,
                            underlyingError: possibleError
                        )
                        completionHandler(.failure(apiError))
                        return
                    }

                    let result = try decoder.decode(MapMatchingResponse.self, from: data)

                    let routeResponse = try RouteResponse(
                        matching: result,
                        options: options,
                        credentials: self.credentials
                    )
                    guard routeResponse.routes != nil else {
                        completionHandler(.failure(.unableToRoute))
                        return
                    }

                    completionHandler(.success(routeResponse))
                } catch {
                    let bailError = DirectionsError(code: nil, message: nil, response: response, underlyingError: error)
                    completionHandler(.failure(bailError))
                }
            }
        }
        requestTask.priority = 1
        requestTask.resume()

        return requestTask
    }

    /// Begins asynchronously refreshing the route with the given identifier, optionally starting from an arbitrary leg
    /// along the route.
    ///
    /// This method retrieves skeleton route data asynchronously from the Mapbox Directions Refresh API over a network
    /// connection. If a connection error or server error occurs, details about the error are passed into the given
    /// completion handler in lieu of the routes.
    ///
    /// - Precondition: Set ``RouteOptions/refreshingEnabled`` to `true` when calculating the original route.
    /// - Parameters:
    ///   - responseIdentifier: The ``RouteResponse/identifier`` value of the ``RouteResponse`` that contains the route
    /// to refresh.
    ///   - routeIndex: The index of the route to refresh in the original ``RouteResponse/routes`` array.
    ///   - startLegIndex: The index of the leg in the route at which to begin refreshing. The response will omit any
    /// leg before this index and refresh any leg from this index to the end of the route. If this argument is omitted,
    /// the entire route is refreshed.
    ///   - completionHandler: The closure (block) to call with the resulting skeleton route data. This closure is
    /// executed on the application’s main thread.
    /// - Returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to
    /// execute, you no longer want the resulting skeleton routes, cancel this task.
    @discardableResult
    open func refreshRoute(
        responseIdentifier: String,
        routeIndex: Int,
        fromLegAtIndex startLegIndex: Int = 0,
        completionHandler: @escaping RouteRefreshCompletionHandler
    ) -> URLSessionDataTask? {
        _refreshRoute(
            responseIdentifier: responseIdentifier,
            routeIndex: routeIndex,
            fromLegAtIndex: startLegIndex,
            currentRouteShapeIndex: nil,
            completionHandler: completionHandler
        )
    }

    /// Begins asynchronously refreshing the route with the given identifier, optionally starting from an arbitrary leg
    /// and point along the route.
    ///
    /// This method retrieves skeleton route data asynchronously from the Mapbox Directions Refresh API over a network
    /// connection. If a connection error or server error occurs, details about the error are passed into the given
    /// completion handler in lieu of the routes.
    ///
    /// - Precondition: Set ``RouteOptions/refreshingEnabled`` to `true` when calculating the original route.
    /// - Parameters:
    ///   - responseIdentifier: The ``RouteResponse/identifier`` value of the ``RouteResponse`` that contains the route
    /// to refresh.
    ///   - routeIndex: The index of the route to refresh in the original ``RouteResponse/routes`` array.
    ///   - startLegIndex: The index of the leg in the route at which to begin refreshing. The response will omit any
    /// leg before this index and refresh any leg from this index to the end of the route. If this argument is omitted,
    /// the entire route is refreshed.
    ///   - currentRouteShapeIndex: The index of the route geometry at which to begin refreshing. Indexed geometry must
    /// be contained by the leg at `startLegIndex`.
    ///   - completionHandler: The closure (block) to call with the resulting skeleton route data. This closure is
    /// executed on the application’s main thread.
    /// - Returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to
    /// execute, you no longer want the resulting skeleton routes, cancel this task.
    @discardableResult
    open func refreshRoute(
        responseIdentifier: String,
        routeIndex: Int,
        fromLegAtIndex startLegIndex: Int = 0,
        currentRouteShapeIndex: Int,
        completionHandler: @escaping RouteRefreshCompletionHandler
    ) -> URLSessionDataTask? {
        _refreshRoute(
            responseIdentifier: responseIdentifier,
            routeIndex: routeIndex,
            fromLegAtIndex: startLegIndex,
            currentRouteShapeIndex: currentRouteShapeIndex,
            completionHandler: completionHandler
        )
    }

    private func _refreshRoute(
        responseIdentifier: String,
        routeIndex: Int,
        fromLegAtIndex startLegIndex: Int,
        currentRouteShapeIndex: Int?,
        completionHandler: @escaping RouteRefreshCompletionHandler
    ) -> URLSessionDataTask? {
        let request: URLRequest = if let currentRouteShapeIndex {
            urlRequest(
                forRefreshing: responseIdentifier,
                routeIndex: routeIndex,
                fromLegAtIndex: startLegIndex,
                currentRouteShapeIndex: currentRouteShapeIndex
            )
        } else {
            urlRequest(
                forRefreshing: responseIdentifier,
                routeIndex: routeIndex,
                fromLegAtIndex: startLegIndex
            )
        }
        let requestTask = urlSession.dataTask(with: request) { possibleData, possibleResponse, possibleError in
            if let urlError = possibleError as? URLError {
                DispatchQueue.main.async {
                    completionHandler(self.credentials, .failure(.network(urlError)))
                }
                return
            }

            guard let response = possibleResponse, ["application/json", "text/html"].contains(response.mimeType) else {
                DispatchQueue.main.async {
                    completionHandler(self.credentials, .failure(.invalidResponse(possibleResponse)))
                }
                return
            }

            guard let data = possibleData else {
                DispatchQueue.main.async {
                    completionHandler(self.credentials, .failure(.noData))
                }
                return
            }

            self.processingQueue.async {
                do {
                    let decoder = JSONDecoder()
                    decoder.userInfo = [
                        .responseIdentifier: responseIdentifier,
                        .routeIndex: routeIndex,
                        .startLegIndex: startLegIndex,
                        .credentials: self.credentials,
                    ]

                    guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                        let apiError = DirectionsError(
                            code: nil,
                            message: nil,
                            response: possibleResponse,
                            underlyingError: possibleError
                        )

                        DispatchQueue.main.async {
                            completionHandler(self.credentials, .failure(apiError))
                        }
                        return
                    }

                    guard (disposition.code == nil && disposition.message == nil) || disposition.code == "Ok" else {
                        let apiError = DirectionsError(
                            code: disposition.code,
                            message: disposition.message,
                            response: response,
                            underlyingError: possibleError
                        )
                        DispatchQueue.main.async {
                            completionHandler(self.credentials, .failure(apiError))
                        }
                        return
                    }

                    let result = try decoder.decode(RouteRefreshResponse.self, from: data)

                    DispatchQueue.main.async {
                        completionHandler(self.credentials, .success(result))
                    }
                } catch {
                    DispatchQueue.main.async {
                        let bailError = DirectionsError(
                            code: nil,
                            message: nil,
                            response: response,
                            underlyingError: error
                        )
                        completionHandler(self.credentials, .failure(bailError))
                    }
                }
            }
        }
        requestTask.priority = 1
        requestTask.resume()
        return requestTask
    }

    open func urlRequest(
        forRefreshing responseIdentifier: String,
        routeIndex: Int,
        fromLegAtIndex startLegIndex: Int
    ) -> URLRequest {
        _urlRequest(
            forRefreshing: responseIdentifier,
            routeIndex: routeIndex,
            fromLegAtIndex: startLegIndex,
            currentRouteShapeIndex: nil
        )
    }

    open func urlRequest(
        forRefreshing responseIdentifier: String,
        routeIndex: Int,
        fromLegAtIndex startLegIndex: Int,
        currentRouteShapeIndex: Int
    ) -> URLRequest {
        _urlRequest(
            forRefreshing: responseIdentifier,
            routeIndex: routeIndex,
            fromLegAtIndex: startLegIndex,
            currentRouteShapeIndex: currentRouteShapeIndex
        )
    }

    private func _urlRequest(
        forRefreshing responseIdentifier: String,
        routeIndex: Int,
        fromLegAtIndex startLegIndex: Int,
        currentRouteShapeIndex: Int?
    ) -> URLRequest {
        var params: [URLQueryItem] = credentials.authenticationParams
        if let currentRouteShapeIndex {
            params.append(URLQueryItem(name: "current_route_geometry_index", value: String(currentRouteShapeIndex)))
        }

        var unparameterizedURL = URL(
            string: "directions-refresh/v1/\(ProfileIdentifier.automobileAvoidingTraffic.rawValue)",
            relativeTo: credentials.host
        )!
        unparameterizedURL.appendPathComponent(responseIdentifier)
        unparameterizedURL.appendPathComponent(String(routeIndex))
        unparameterizedURL.appendPathComponent(String(startLegIndex))
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!

        components.queryItems = params

        let getURL = components.url!
        var request = URLRequest(url: getURL)
        request.setupUserAgentString()
        return request
    }

    /// The GET HTTP URL used to fetch the routes from the API.
    ///
    /// After requesting the URL returned by this method, you can parse the JSON data in the response and pass it into
    /// the ``Route/init(from:)`` initializer. Alternatively, you can use the ``calculate(_:completionHandler:)-8je4q``
    /// method, which automatically sends the request and parses the response.
    /// - Parameter options: A ``DirectionsOptions`` object specifying the requirements for the resulting routes.
    /// - Returns: The URL to send the request to.
    open func url(forCalculating options: DirectionsOptions) -> URL {
        return url(forCalculating: options, httpMethod: "GET")
    }

    /// The HTTP URL used to fetch the routes from the API using the specified HTTP method.
    ///
    /// The query part of the URL is generally suitable for GET requests. However, if the URL is exceptionally long, it
    /// may be more appropriate to send a POST request to a URL without the query part, relegating the query to the body
    /// of the HTTP request. Use the `urlRequest(forCalculating:)` method to get an HTTP request that is a GET or POST
    /// request as necessary.
    ///
    /// After requesting the URL returned by this method, you can parse the JSON data in the response and pass it into
    /// the ``Route/init(from:)`` initializer. Alternatively, you can use the ``calculate(_:completionHandler:)-8je4q``
    /// method, which automatically sends the request and parses the response.
    /// - Parameters:
    ///   - options: A ``DirectionsOptions`` object specifying the requirements for the resulting routes.
    ///   - httpMethod: The HTTP method to use. The value of this argument should match the `URLRequest.httpMethod` of
    /// the request you send. Currently, only GET and POST requests are supported by the API.
    /// - Returns: The URL to send the request to.
    open func url(forCalculating options: DirectionsOptions, httpMethod: String) -> URL {
        Self.url(forCalculating: options, credentials: credentials, httpMethod: httpMethod)
    }

    /// The GET HTTP URL used to fetch the routes from the API.
    ///
    /// After requesting the URL returned by this method, you can parse the JSON data in the response and pass it into
    /// the ``Route/init(from:)`` initializer. Alternatively, you can use the
    /// ``calculate(_:completionHandler:)-8je4q`` method, which automatically sends the request and parses the response.
    ///
    ///  - parameter options: A ``DirectionsOptions`` object specifying the requirements for the resulting routes.
    ///  - parameter credentials: ``Credentials`` data applied to the request.
    ///  - returns: The URL to send the request to.
    public static func url(forCalculating options: DirectionsOptions, credentials: Credentials) -> URL {
        return url(forCalculating: options, credentials: credentials, httpMethod: "GET")
    }

    /// The HTTP URL used to fetch the routes from the API using the specified HTTP method.
    ///
    /// The query part of the URL is generally suitable for GET requests. However, if the URL is exceptionally long, it
    /// may be more appropriate to send a POST request to a URL without the query part, relegating the query to the body
    /// of the HTTP request. Use the `urlRequest(forCalculating:)` method to get an HTTP request that is a GET or POST
    /// request as necessary.
    ///
    /// After requesting the URL returned by this method, you can parse the JSON data in the response and pass it into
    /// the ``Route/init(from:)`` initializer. Alternatively, you can use the ``calculate(_:completionHandler:)-8je4q``
    /// method, which automatically sends the request and parses the response.
    /// - Parameters:
    ///   - options: A ``DirectionsOptions`` object specifying the requirements for the resulting routes.
    ///   - credentials: ``Credentials`` data applied to the request.
    ///   - httpMethod: The HTTP method to use. The value of this argument should match the `URLRequest.httpMethod` of
    /// the request you send. Currently, only GET and POST requests are supported by the API.
    /// - Returns: The URL to send the request to.
    public static func url(
        forCalculating options: DirectionsOptions,
        credentials: Credentials,
        httpMethod: String
    ) -> URL {
        let includesQuery = httpMethod != "POST"
        var params = (includesQuery ? options.urlQueryItems : [])
        params.append(contentsOf: credentials.authenticationParams)

        let unparameterizedURL = URL(path: includesQuery ? options.path : options.abridgedPath, host: credentials.host)
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }

    /// The HTTP request used to fetch the routes from the API.
    ///
    /// The returned request is a GET or POST request as necessary to accommodate URL length limits.
    ///
    /// After sending the request returned by this method, you can parse the JSON data in the response and pass it into
    /// the ``Route.init(json:waypoints:profileIdentifier:)`` initializer. Alternatively, you can use the
    /// `calculate(_:options:)` method, which automatically sends the request and parses the response.
    ///
    /// - Parameter options: A ``DirectionsOptions`` object specifying the requirements for the resulting routes.
    /// - Returns: A GET or POST HTTP request to calculate the specified options.
    open func urlRequest(forCalculating options: DirectionsOptions) -> URLRequest {
        if options.waypoints.count < 2 { assertionFailure("waypoints array requires at least 2 waypoints") }
        let getURL = Self.url(forCalculating: options, credentials: credentials, httpMethod: "GET")
        var request = URLRequest(url: getURL)
        if getURL.absoluteString.count > MaximumURLLength {
            request.url = Self.url(forCalculating: options, credentials: credentials, httpMethod: "POST")

            let body = options.httpBody.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = body
        }
        request.setupUserAgentString()
        return request
    }
}

@available(*, unavailable)
extension Directions: @unchecked Sendable {}

/// Keys to pass to populate a `userInfo` dictionary, which is passed to the `JSONDecoder` upon trying to decode a
/// ``RouteResponse``, ``MapMatchingResponse`` or ``RouteRefreshResponse``.
extension CodingUserInfoKey {
    public static let options = CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.routeOptions")!
    public static let httpResponse = CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.httpResponse")!
    public static let credentials = CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.credentials")!
    public static let tracepoints = CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.tracepoints")!

    public static let responseIdentifier =
        CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.responseIdentifier")!
    public static let routeIndex = CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.routeIndex")!
    public static let startLegIndex = CodingUserInfoKey(rawValue: "com.mapbox.directions.coding.startLegIndex")!
}

extension Credentials {
    fileprivate var authenticationParams: [URLQueryItem] {
        var params: [URLQueryItem] = [
            URLQueryItem(name: "access_token", value: accessToken),
        ]

        if let skuToken {
            params.append(URLQueryItem(name: "sku", value: skuToken))
        }
        return params
    }
}
