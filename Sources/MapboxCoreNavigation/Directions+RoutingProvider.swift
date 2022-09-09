import Foundation
import MapboxDirections

extension URLSessionDataTask: NavigationProviderRequest {
    public var requestIdentifier: UInt64 {
        UInt64(taskIdentifier)
    }
}

extension Directions: RoutingProvider {
    
    @discardableResult public func calculateRoutes(options: RouteOptions,
                                                   completionHandler: @escaping IndexedRouteResponseCompletionHandler) -> NavigationProviderRequest? {
        return calculate(options, completionHandler: { _, result in
            switch result {
            case .success(let routeResponse):
                completionHandler(.success(IndexedRouteResponse(routeResponse: routeResponse,
                                                                routeIndex: 0,
                                                                responseOrigin: .online)))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        })
    }
    
    @available(*, deprecated, renamed: "calculateRoutes(options:completionHandler:)")
    @discardableResult public func calculateRoutes(options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) -> NavigationProviderRequest? {
        return calculate(options, completionHandler: completionHandler)
    }
    
    @discardableResult public func calculateRoutes(options: MatchOptions, completionHandler: @escaping MatchCompletionHandler) -> NavigationProviderRequest? {
        return calculate(options, completionHandler: completionHandler)
    }

    @discardableResult public func refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex: UInt32, completionHandler: @escaping RouteCompletionHandler) -> NavigationProviderRequest? {
        _refreshRoute(indexedRouteResponse: indexedRouteResponse,
                      fromLegAtIndex: Int(fromLegAtIndex),
                      currentRouteShapeIndex: nil,
                      currentLegShapeIndex: nil,
                      completionHandler: completionHandler)
    }

    @discardableResult public func refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex: UInt32, currentRouteShapeIndex: Int, currentLegShapeIndex: Int, completionHandler: @escaping RouteCompletionHandler) -> NavigationProviderRequest? {
        _refreshRoute(indexedRouteResponse: indexedRouteResponse,
                      fromLegAtIndex: Int(fromLegAtIndex),
                      currentRouteShapeIndex: currentRouteShapeIndex,
                      currentLegShapeIndex: currentLegShapeIndex,
                      completionHandler: completionHandler)
    }
    
    private func _refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex startLegIndex: Int, currentRouteShapeIndex: Int?, currentLegShapeIndex: Int?, completionHandler: @escaping RouteCompletionHandler) -> NavigationProviderRequest? {
        guard case let .route(routeOptions) = indexedRouteResponse.routeResponse.options else {
            preconditionFailure("Invalid route data passed for refreshing. Expected `RouteResponse` containing `.route` `ResponseOptions` but got `.match`.")
        }
        
        let session = (options: routeOptions as DirectionsOptions,
                       credentials: self.credentials)
        
        guard let responseIdentifier = indexedRouteResponse.routeResponse.identifier else {
            DispatchQueue.main.async {
                completionHandler(session, .failure(.noData))
            }
            return nil
        }

        let completionHandler: RouteRefreshCompletionHandler = { credentials, result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(session, .failure(error))
                }
            case .success(let routeRefreshResponse):
                DispatchQueue.global().async {
                    do {
                        let routeResponse = try indexedRouteResponse.routeResponse.copy(with: routeOptions)
                        let route = routeResponse.routes?[indexedRouteResponse.routeIndex]
                        if let currentLegShapeIndex = currentLegShapeIndex {
                            route?.refreshLegAttributes(from: routeRefreshResponse.route,
                                                        legIndex: startLegIndex,
                                                        legShapeIndex: currentLegShapeIndex)
                            route?.refreshLegIncidents(from: routeRefreshResponse.route,
                                                       legIndex: startLegIndex,
                                                       legShapeIndex: currentLegShapeIndex)
                        } else {
                            route?.refreshLegAttributes(from: routeRefreshResponse.route)
                            route?.refreshLegIncidents(from: routeRefreshResponse.route)
                        }

                        DispatchQueue.main.async {
                            completionHandler(session, .success(routeResponse))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completionHandler(session, .failure(.unknown(response: nil, underlying: error, code: nil, message: nil)))
                        }
                    }
                }
            }
        }

        if let currentRouteShapeIndex = currentRouteShapeIndex {
            return refreshRoute(responseIdentifier: responseIdentifier,
                                routeIndex: indexedRouteResponse.routeIndex,
                                fromLegAtIndex: startLegIndex,
                                currentRouteShapeIndex: currentRouteShapeIndex,
                                completionHandler: completionHandler)
        } else {
            return refreshRoute(responseIdentifier: responseIdentifier,
                                routeIndex: indexedRouteResponse.routeIndex,
                                fromLegAtIndex: startLegIndex,
                                completionHandler: completionHandler)
        }
    }
}

extension RouteResponse {
    func copy(with options: DirectionsOptions) throws -> RouteResponse {
        var copy = self
        copy.routes = try copy.routes?.map { try $0.copy(with: options) }
        return copy
    }
}

extension Route {
    func copy(with options: DirectionsOptions) throws -> Route {
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        let encoded = try encoder.encode(self)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        return try decoder.decode(Self.self, from: encoded)
    }
}
