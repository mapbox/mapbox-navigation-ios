import _MapboxNavigationHelpers
import Foundation
import MapboxDirections
@preconcurrency import MapboxNavigationNative_Private
import Turf

/// Contains a selection of ``NavigationRoute`` and it's related ``AlternativeRoute``'s, which can be sued for
/// navigation.
public struct NavigationRoutes: Equatable, @unchecked Sendable {
    /// A route choosed to navigate on.
    public internal(set) var mainRoute: NavigationRoute
    /// Suggested alternative routes.
    ///
    /// To select one of the alterntives as a main route, see ``selectingAlternativeRoute(at:)`` and
    /// ``selecting(alternativeRoute:)`` methods.
    public var alternativeRoutes: [AlternativeRoute] {
        allAlternativeRoutesWithIgnored.filter { !$0.isForkPointPassed }
    }

    /// A list of ``Waypoint``s  visited along the routes.
    public internal(set) var waypoints: [Waypoint]
    /// A deadline after which  the routes from this `RouteResponse` are eligable for refreshing.
    ///
    /// `nil` value indicates that route refreshing is not available for related routes.
    public internal(set) var refreshInvalidationDate: Date?
    /// Contains a map of `JSONObject`'s which were appended in the original route response, but are not recognized by
    /// the SDK.
    public internal(set) var foreignMembers: JSONObject = [:]

    var allAlternativeRoutesWithIgnored: [AlternativeRoute]

    var isCustomExternalRoute: Bool {
        mainRoute.nativeRouteInterface.getRouterOrigin() == .customExternal
    }

    var mapboxApi: MapboxAPI {
        mainRoute.nativeRouteInterface.getMapboxAPI()
    }

    init(routesData: RoutesData, options: ResponseOptions) async throws {
        let routeResponse = try await routesData.primaryRoute().convertToDirectionsRouteResponse(options)
        try self.init(routesData: routesData, routeResponse: routeResponse)
    }

    private init(routesData: RoutesData, routeResponse: RouteResponse) throws {
        guard let routes = routeResponse.routes else {
            Log.error("Unable to get routes", category: .navigation)
            throw NavigationRoutesError.emptyRoutes
        }

        let mainRouteIndex = Int(routesData.primaryRoute().getRouteIndex())
        guard routes.indices.contains(mainRouteIndex) else {
            Log.error("Routes mismatched", category: .navigation)
            throw NavigationRoutesError.incorrectRoutesNumber
        }

        let mainRoute = routes[mainRouteIndex]
        let requestOptions = routeResponse.options

        var alternativeRoutes = [AlternativeRoute]()
        for routeAlternative in routesData.alternativeRoutes() {
            let index = Int(routeAlternative.route.getRouteIndex())
            guard routes.indices.contains(index),
                  let alternativeRoute = AlternativeRoute(
                      mainRoute: mainRoute,
                      alternativeRoute: routes[index],
                      nativeRouteAlternative: routeAlternative,
                      requestOptions: requestOptions
                  )
            else {
                Log.error("Unable to convert alternative route with id: \(routeAlternative.id)", category: .navigation)
                continue
            }

            alternativeRoutes.append(alternativeRoute)
        }

        self.mainRoute = NavigationRoute(
            route: mainRoute,
            nativeRoute: routesData.primaryRoute(),
            requestOptions: requestOptions
        )
        self.allAlternativeRoutesWithIgnored = alternativeRoutes
        self.waypoints = routeResponse.waypoints ?? []
        self.refreshInvalidationDate = routeResponse.refreshInvalidationDate
        self.foreignMembers = routeResponse.foreignMembers
    }

    init(
        mainRoute: NavigationRoute,
        alternativeRoutes: [AlternativeRoute],
        waypoints: [Waypoint],
        refreshInvalidationDate: Date? = nil,
        foreignMembers: JSONObject = [:]
    ) async {
        self.mainRoute = mainRoute
        self.allAlternativeRoutesWithIgnored = alternativeRoutes
        self.waypoints = waypoints
        self.refreshInvalidationDate = refreshInvalidationDate
        self.foreignMembers = foreignMembers
    }

    @_spi(MapboxInternal)
    public init(routeResponse: RouteResponse, routeIndex: Int, responseOrigin: RouterOrigin) async throws {
        let options = NavigationRoutes.validatedRouteOptions(options: routeResponse.options)

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        let routeData = try encoder.encode(routeResponse)

        let routeRequest = Directions.url(forCalculating: options, credentials: routeResponse.credentials)
            .absoluteString

        let routeParserClient = Environment.shared.routeParserClient
        let parsedRoutes = routeParserClient.parseDirectionsResponseForResponseDataRef(
            .init(data: routeData),
            routeRequest,
            responseOrigin
        )
        if parsedRoutes.isValue(),
           var routes = parsedRoutes.value as? [RouteInterface],
           routes.indices.contains(routeIndex)
        {
            let routesData = routeParserClient.createRoutesData(
                routes.remove(at: routeIndex),
                routes
            )
            let navigationRoutes = try NavigationRoutes(routesData: routesData, routeResponse: routeResponse)
            self = navigationRoutes
            self.waypoints = routeResponse.waypoints ?? []
            self.refreshInvalidationDate = routeResponse.refreshInvalidationDate
            self.foreignMembers = routeResponse.foreignMembers
        } else if parsedRoutes.isError(),
                  let error = parsedRoutes.error
        {
            Log.error("Failed to parse routes with error: \(error)", category: .navigation)
            throw NavigationRoutesError.responseParsingError(description: error as String)
        } else {
            Log.error("Unexpected error during routes parsing.", category: .navigation)
            throw NavigationRoutesError.unknownError
        }
    }

    init(
        mapMatchingResponse: MapMatchingResponse,
        routeIndex: Int,
        responseOrigin: RouterOrigin
    ) async throws {
        let options = mapMatchingResponse.options
        let credentials = mapMatchingResponse.credentials

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        encoder.userInfo[.credentials] = credentials

        let responseData = try encoder.encode(mapMatchingResponse)

        let request = Directions.url(forCalculating: options, credentials: credentials).absoluteString

        let routeParserClient = Environment.shared.routeParserClient
        let parsedRoutes = routeParserClient.parseMapMatchingResponseForResponseDataRef(
            .init(data: responseData),
            request,
            responseOrigin
        )
        let requestOptions: ResponseOptions = .match(options)

        if parsedRoutes.isValue(),
           var routes = parsedRoutes.value as? [RouteInterface],
           routes.indices.contains(routeIndex)
        {
            let routesData = routeParserClient.createRoutesData(
                routes.remove(at: routeIndex),
                routes
            )

            let routeResponse = try RouteResponse(
                matching: mapMatchingResponse,
                options: options,
                credentials: credentials
            )

            let routes = routeResponse.routes ?? []

            guard !routes.isEmpty else {
                Log.error("Unable to get routes", category: .navigation)
                throw NavigationRoutesError.emptyRoutes
            }

            let mainRouteIndex = Int(routesData.primaryRoute().getRouteIndex())
            guard routes.indices.contains(mainRouteIndex) else {
                Log.error("Routes mismatched", category: .navigation)
                throw NavigationRoutesError.incorrectRoutesNumber
            }

            let mainRoute = routes[mainRouteIndex]

            let waypoints = routeResponse.waypoints ?? []

            var alternativeRoutes = [AlternativeRoute]()
            for routeAlternative in routesData.alternativeRoutes() {
                let index = Int(routeAlternative.route.getRouteIndex())
                guard routes.indices.contains(index),
                      let alternativeRoute = AlternativeRoute(
                          mainRoute: mainRoute,
                          alternativeRoute: routes[index],
                          nativeRouteAlternative: routeAlternative,
                          requestOptions: requestOptions
                      )
                else {
                    Log.error(
                        "Unable to convert alternative route with id: \(routeAlternative.id)",
                        category: .navigation
                    )
                    continue
                }
                alternativeRoutes.append(alternativeRoute)
            }

            self.mainRoute = NavigationRoute(
                route: mainRoute,
                nativeRoute: routesData.primaryRoute(),
                requestOptions: requestOptions
            )
            self.waypoints = waypoints
            self.allAlternativeRoutesWithIgnored = alternativeRoutes
            self.foreignMembers = mapMatchingResponse.foreignMembers

        } else if parsedRoutes.isError(),
                  let error = parsedRoutes.error
        {
            Log.error("Failed to parse routes with error: \(error)", category: .navigation)
            throw NavigationRoutesError.responseParsingError(description: error as String)
        } else {
            Log.error("Unexpected error during routes parsing.", category: .navigation)
            throw NavigationRoutesError.unknownError
        }
    }

    func asRoutesData() -> RoutesData {
        let routeParserClient = Environment.shared.routeParserClient
        return routeParserClient.createRoutesData(
            mainRoute.nativeRouteInterface,
            alternativeRoutes.map(\.nativeRoute)
        )
    }

    func selectingMostSimilar(to route: Route) async -> NavigationRoutes {
        let target = route.description

        var candidates = [mainRoute.route]
        candidates.append(contentsOf: alternativeRoutes.map(\.route))

        guard let bestCandidate = candidates.map({
            (route: $0, editDistance: $0.description.minimumEditDistance(to: target))
        }).enumerated().min(by: { $0.element.editDistance < $1.element.editDistance }) else { return self }

        // If the most similar route is still more than 50% different from the original route,
        // we fallback to the fastest route which index is 0.
        let totalLength = Double(bestCandidate.element.route.description.count + target.description.count)
        guard totalLength > 0 else { return self }
        let differenceScore = Double(bestCandidate.element.editDistance) / totalLength
        // Comparing to 0.25 as for "replacing the half of the string", since we add target and candidate lengths
        // together
        // Algorithm proposal: https://github.com/mapbox/mapbox-navigation-ios/pull/3664#discussion_r772194977
        guard differenceScore < 0.25 else { return self }

        if bestCandidate.offset > 0 {
            return await selectingAlternativeRoute(at: bestCandidate.offset - 1) ?? self
        } else {
            return self
        }
    }

    /// Returns a new ``NavigationRoutes`` instance, wich has corresponding ``AlternativeRoute`` set as the main one.
    ///
    /// This operation requires re-parsing entire routes data, because all alternative's relative stats will not remain
    /// the same after changing the ``mainRoute``.
    ///
    /// - parameter index: Index  in ``alternativeRoutes`` array to assign as a main route.
    /// - returns: New ``NavigationRoutes`` instance,  with new `alternativeRoute` set as the main one, or `nil` if the
    /// `index` is out of bounds..
    public func selectingAlternativeRoute(at index: Int) async -> NavigationRoutes? {
        guard self.alternativeRoutes.indices.contains(index) else {
            return nil
        }
        var alternativeRoutes = alternativeRoutes

        let alternativeRoute = alternativeRoutes.remove(at: index)

        let routesData = Environment.shared.routeParserClient.createRoutesData(
            alternativeRoute.nativeRoute,
            alternativeRoutes.map(\.nativeRoute) + [mainRoute.nativeRouteInterface]
        )

        let newMainRoute = NavigationRoute(
            route: alternativeRoute.route,
            nativeRoute: alternativeRoute.nativeRoute,
            requestOptions: alternativeRoute.requestOptions
        )

        var newAlternativeRoutes = alternativeRoutes.compactMap { oldAlternative -> AlternativeRoute? in
            guard let nativeRouteAlternative = routesData.alternativeRoutes()
                .first(where: { $0.route.getRouteId() == oldAlternative.routeId.rawValue })
            else {
                Log.warning(
                    "Unable to create an alternative route for \(oldAlternative.routeId.rawValue)",
                    category: .navigation
                )
                return nil
            }
            return AlternativeRoute(
                mainRoute: newMainRoute.route,
                alternativeRoute: oldAlternative.route,
                nativeRouteAlternative: nativeRouteAlternative,
                requestOptions: oldAlternative.requestOptions
            )
        }

        if let nativeRouteAlternative = routesData.alternativeRoutes()
            .first(where: { $0.route.getRouteId() == mainRoute.routeId.rawValue }),
            let newAlternativeRoute = AlternativeRoute(
                mainRoute: newMainRoute.route,
                alternativeRoute: mainRoute.route,
                nativeRouteAlternative: nativeRouteAlternative,
                requestOptions: mainRoute.requestOptions
            )
        {
            newAlternativeRoutes.append(newAlternativeRoute)
        } else {
            Log.warning(
                "Unable to create an alternative route: \(mainRoute.routeId.rawValue) for a new main route: \(alternativeRoute.routeId.rawValue)",
                category: .navigation
            )
        }

        return await .init(
            mainRoute: newMainRoute,
            alternativeRoutes: newAlternativeRoutes,
            waypoints: waypoints,
            refreshInvalidationDate: refreshInvalidationDate,
            foreignMembers: foreignMembers
        )
    }

    /// Returns a new ``NavigationRoutes`` instance, wich has corresponding ``AlternativeRoute`` set as the main one.
    ///
    /// This operation requires re-parsing entire routes data, because all alternative's relative stats will not remain
    /// the same after changing the ``mainRoute``.
    ///
    /// - parameter alternativeRoute: An ``AlternativeRoute`` to assign as main.
    /// - returns: New ``NavigationRoutes`` instance,  with `alternativeRoute` set as the main one, or `nil` if current
    /// instance does not contain this alternative.
    public func selecting(alternativeRoute: AlternativeRoute) async -> NavigationRoutes? {
        guard let index = alternativeRoutes.firstIndex(where: { $0 == alternativeRoute }) else {
            return nil
        }
        return await selectingAlternativeRoute(at: index)
    }

    static func validatedRouteOptions(options: ResponseOptions) -> RouteOptions {
        switch options {
        case .match(let matchOptions):
            return RouteOptions(matchOptions: matchOptions)
        case .route(let options):
            return options
        }
    }

    /// A convenience method to get a list of all included `Route`s, optionally filtering it in the process.
    ///
    /// - parameter isIncluded: A callback, used to filter the routes.
    /// - returns: A list of all included routes, filtered by `isIncluded` rule.
    public func allRoutes(_ isIncluded: (Route) -> Bool = { _ in true }) -> [Route] {
        var routes: [Route] = []
        if isIncluded(mainRoute.route) {
            routes.append(mainRoute.route)
        }
        routes.append(contentsOf: alternativeRoutes.lazy.map(\.route).filter(isIncluded))
        return routes
    }

    /// Convenience method to comare routes set with another ``NavigationRoutes`` instance.
    ///
    /// - note: The comparison is done by ``NavigationRoute/routeId``.
    ///
    /// - parameter otherRoutes: A ``NavigationRoutes`` instance against which to compare.
    /// - returns: `true` if `otherRoutes` contains exactly the same collection of routes, `false` - otherwise.
    public func containsSameRoutes(as otherRoutes: NavigationRoutes) -> Bool {
        let currentRouteIds = Set(alternativeRoutes.map(\.routeId) + [mainRoute.routeId])
        let newRouteIds = Set(otherRoutes.alternativeRoutes.map(\.routeId) + [otherRoutes.mainRoute.routeId])
        return currentRouteIds == newRouteIds
    }
}

/// Wraps a route object used across the Navigation SDK.
public struct NavigationRoute: Sendable {
    /// // A `Route` object that the current navigation route represents.
    public let route: Route
    /// Unique route id.
    public let routeId: RouteId
    /// Options used to request this route.
    public let requestOptions: ResponseOptions

    @_spi(MapboxInternal)
    public let nativeRouteInterface: RouteInterface

    @available(*, deprecated, message: "This property is no longer supported.")
    public var nativeRoute: RouteInterface {
        nativeRouteInterface
    }

    @available(*, deprecated, message: "This initializer is no longer supported.")
    public init?(nativeRoute: RouteInterface) async {
        await self.init(nativeRoute: nativeRoute, directionsOptionsType: RouteOptions.self)
    }

    init?(nativeRoute: RouteInterface, directionsOptionsType: DirectionsOptions.Type) async {
        guard let requestOptions = nativeRoute.getResponseOptions(directionsOptionsType),
              let route = try? await nativeRoute.convertToDirectionsRoute(requestOptions)
        else {
            return nil
        }

        self.init(route: route, nativeRoute: nativeRoute, requestOptions: requestOptions)
    }

    init(route: Route, nativeRoute: RouteInterface, requestOptions: ResponseOptions) {
        self.nativeRouteInterface = nativeRoute
        self.route = route
        self.routeId = .init(rawValue: nativeRoute.getRouteId())
        self.requestOptions = requestOptions
    }

    public var routeOptions: RouteOptions? {
        switch requestOptions {
        case .route(let options):
            return options
        case .match(let matchOptions):
            return RouteOptions(matchOptions: matchOptions)
        }
    }
}

extension NavigationRoute: Equatable {
    public static func == (lhs: NavigationRoute, rhs: NavigationRoute) -> Bool {
        return lhs.routeId == rhs.routeId &&
            lhs.route == rhs.route
    }

    var directionOptions: DirectionsOptions {
        requestOptions.directionsOptions
    }
}

extension RouteInterface {
    func getResponseOptions(_ type: DirectionsOptions.Type) -> ResponseOptions? {
        type.requestOptions(from: getRequestUri())
    }

    fileprivate func convertToDirectionsRouteResponse(_ type: DirectionsOptions.Type) async throws -> RouteResponse {
        guard let requestOptions = getResponseOptions(type) else {
            throw NavigationRoutesError.noRequestData
        }
        return try await convertToDirectionsRouteResponse(requestOptions)
    }

    fileprivate func convertToDirectionsRouteResponse(_ requestOptions: ResponseOptions) async throws
    -> RouteResponse {
        guard let requestURL = URL(string: getRequestUri()) else {
            Log.error(
                "Couldn't extract response and request data to parse `RouteInterface` into `RouteResponse`",
                category: .navigation
            )
            throw NavigationRoutesError.noRequestData
        }

        let credentials = Credentials(requestURL: requestURL)
        let decoder = JSONDecoder()
        switch requestOptions {
        case .route(let routeOptions):
            decoder.userInfo[.options] = routeOptions
        case .match(let matchOptions):
            decoder.userInfo[.options] = matchOptions
        }
        decoder.userInfo[.credentials] = credentials

        do {
            let ref = getResponseJsonRef()
            return try decoder.decode(RouteResponse.self, from: ref.data)
        } catch {
            Log.error(
                "Couldn't parse `RouteInterface` into `RouteResponse` with error: \(error)",
                category: .navigation
            )
            throw NavigationRoutesError.encodingError(underlyingError: error)
        }
    }

    func convertToDirectionsRoute(_ type: DirectionsOptions.Type) async throws -> Route {
        guard let requestOptions = getResponseOptions(type) else {
            throw NavigationRoutesError.noRequestData
        }
        return try await convertToDirectionsRoute(requestOptions)
    }

    func convertToDirectionsRoute(_ requestOptions: ResponseOptions) async throws -> Route {
        do {
            guard let routes = try await convertToDirectionsRouteResponse(requestOptions).routes else {
                Log.error("Converting to directions route yielded no routes.", category: .navigation)
                throw NavigationRoutesError.emptyRoutes
            }
            guard routes.count > getRouteIndex() else {
                Log.error(
                    "Converting to directions route yielded incorrect number of routes (expected at least \(getRouteIndex() + 1) but have \(routes.count).",
                    category: .navigation
                )
                throw NavigationRoutesError.incorrectRoutesNumber
            }
            return routes[Int(getRouteIndex())]
        } catch {
            Log.error(
                "Parsing `RouteInterface` into `Route` resulted in no routes",
                category: .navigation
            )
            throw error
        }
    }
}

public struct RouteId: Hashable, Sendable, Codable, CustomStringConvertible {
    var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String {
        "RouteId(\(rawValue)"
    }
}

/// The error describing a possible cause of failing to instantiate the ``NavigationRoutes`` object.
public enum NavigationRoutesError: Error {
    /// Could not correctly encode provided data into a valid JSON.
    ///
    /// See the associated error for more details.
    case encodingError(underlyingError: Error?)
    /// Failed to compose routes object(s) from the JSON representation.
    case responseParsingError(description: String)
    /// Could not extract route request parameters from the JSON representation.
    case noRequestData
    /// Routes parsing resulted in an empty routes list.
    case emptyRoutes
    /// The number of decoded routes does not match the expected amount
    case incorrectRoutesNumber
    /// An unexpected error occurred during parsing.
    case unknownError
}
