import _MapboxNavigationHelpers
import Foundation
import MapboxDirections
@preconcurrency import MapboxNavigationNative
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
        mainRoute.nativeRoute.getRouterOrigin() == .customExternal
    }

    init(routesData: RoutesData) async throws {
        let routeResponse = try await routesData.primaryRoute().convertToDirectionsRouteResponse()
        try self.init(routesData: routesData, routeResponse: routeResponse)
    }

    private init(routesData: RoutesData, routeResponse: RouteResponse) throws {
        guard let routes = routeResponse.routes else {
            Log.error("Unable to get routes", category: .navigation)
            throw NavigationRoutesError.emptyRoutes
        }

        guard routes.count == routesData.alternativeRoutes().count + 1 else {
            Log.error("Routes mismatched", category: .navigation)
            throw NavigationRoutesError.incorrectRoutesNumber
        }

        let mainRoute = routes[Int(routesData.primaryRoute().getRouteIndex())]

        var alternativeRoutes = [AlternativeRoute]()
        for routeAlternative in routesData.alternativeRoutes() {
            guard let alternativeRoute = AlternativeRoute(
                mainRoute: mainRoute,
                alternativeRoute: routes[Int(routeAlternative.route.getRouteIndex())],
                nativeRouteAlternative: routeAlternative
            ) else {
                Log.error("Unable to convert alternative route with id: \(routeAlternative.id)", category: .navigation)
                continue
            }

            alternativeRoutes.append(alternativeRoute)
        }

        self.mainRoute = NavigationRoute(route: mainRoute, nativeRoute: routesData.primaryRoute())
        self.allAlternativeRoutesWithIgnored = alternativeRoutes
        self.waypoints = routeResponse.waypoints ?? []
        self.refreshInvalidationDate = routeResponse.refreshInvalidationDate
        self.foreignMembers = routeResponse.foreignMembers
    }

    init(mainRoute: NavigationRoute, alternativeRoutes: [AlternativeRoute]) async {
        self.mainRoute = mainRoute
        self.allAlternativeRoutesWithIgnored = alternativeRoutes

        let response = try? await mainRoute.nativeRoute.convertToDirectionsRouteResponse()
        self.waypoints = response?.waypoints ?? []
        self.refreshInvalidationDate = response?.refreshInvalidationDate
        if let foreignMembers = response?.foreignMembers {
            self.foreignMembers = foreignMembers
        }
    }

    @_spi(MapboxInternal)
    public init(routeResponse: RouteResponse, routeIndex: Int, responseOrigin: RouterOrigin) async throws {
        let options = NavigationRoutes.validatedRouteOptions(options: routeResponse.options)

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        let routeData = try encoder.encode(routeResponse)

        let routeRequest = Directions.url(forCalculating: options, credentials: routeResponse.credentials)
            .absoluteString

        let parsedRoutes = RouteParser.parseDirectionsResponse(
            forResponseDataRef: .init(data: routeData),
            request: routeRequest,
            routeOrigin: responseOrigin
        )
        if parsedRoutes.isValue(),
           var routes = parsedRoutes.value as? [RouteInterface],
           routes.indices.contains(routeIndex)
        {
            let routesData = RouteParser.createRoutesData(
                forPrimaryRoute: routes.remove(at: routeIndex),
                alternativeRoutes: routes
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

    func asRoutesData() -> RoutesData {
        return RouteParser.createRoutesData(
            forPrimaryRoute: mainRoute.nativeRoute,
            alternativeRoutes: alternativeRoutes.map(\.nativeRoute)
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

        let routesData = RouteParser.createRoutesData(
            forPrimaryRoute: alternativeRoute.nativeRoute,
            alternativeRoutes: alternativeRoutes.map(\.nativeRoute) + [mainRoute.nativeRoute]
        )

        let newMainRoute = NavigationRoute(route: alternativeRoute.route, nativeRoute: alternativeRoute.nativeRoute)

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
                nativeRouteAlternative: nativeRouteAlternative
            )
        }

        if let nativeRouteAlternative = routesData.alternativeRoutes()
            .first(where: { $0.route.getRouteId() == mainRoute.routeId.rawValue }),
            let newAlternativeRoute = AlternativeRoute(
                mainRoute: newMainRoute.route,
                alternativeRoute: mainRoute.route,
                nativeRouteAlternative: nativeRouteAlternative
            )
        {
            newAlternativeRoutes.append(newAlternativeRoute)
        } else {
            Log.warning(
                "Unable to create an alternative route: \(mainRoute.routeId.rawValue) for a new main route: \(alternativeRoute.routeId.rawValue)",
                category: .navigation
            )
        }

        return await .init(mainRoute: newMainRoute, alternativeRoutes: newAlternativeRoutes)
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

    public let nativeRoute: RouteInterface

    public init?(nativeRoute: RouteInterface) async {
        self.nativeRoute = nativeRoute
        self.routeId = .init(rawValue: nativeRoute.getRouteId())

        guard let route = try? await nativeRoute.convertToDirectionsRoute() else {
            return nil
        }

        self.route = route
    }

    init(route: Route, nativeRoute: RouteInterface) {
        self.nativeRoute = nativeRoute
        self.route = route
        self.routeId = .init(rawValue: nativeRoute.getRouteId())
    }

    private let _routeOptions: NSLocked<(initialized: Bool, options: RouteOptions?)> = .init((false, nil))
    public var routeOptions: RouteOptions? {
        _routeOptions.mutate { state in
            if state.initialized {
                return state.options
            } else {
                state.initialized = true
                if let newOptions = getRouteOptions() {
                    state.options = newOptions
                    return newOptions
                } else {
                    return nil
                }
            }
        }
    }

    private func getRouteOptions() -> RouteOptions? {
        guard let url = URL(string: nativeRoute.getRequestUri()) else {
            return nil
        }

        return RouteOptions(url: url)
    }
}

extension NavigationRoute: Equatable {
    public static func == (lhs: NavigationRoute, rhs: NavigationRoute) -> Bool {
        return lhs.routeId == rhs.routeId &&
            lhs.route == rhs.route
    }
}

extension RouteInterface {
    func convertToDirectionsRouteResponse() async throws -> RouteResponse {
        guard let requestURL = URL(string: getRequestUri()),
              let routeOptions = RouteOptions(url: requestURL)
        else {
            Log.error(
                "Couldn't extract response and request data to parse `RouteInterface` into `RouteResponse`",
                category: .navigation
            )
            throw NavigationRoutesError.noRequestData
        }

        let credentials = Credentials(requestURL: requestURL)
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
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

    func convertToDirectionsRoute() async throws -> Route {
        do {
            guard let routes = try await convertToDirectionsRouteResponse().routes else {
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
