import Foundation
import MapboxDirections

extension URLSessionDataTask: NavigationProviderRequest {
    public var requestIdentifier: UInt64 {
        UInt64(taskIdentifier)
    }
}

extension Directions: RoutingProvider {
    
    @discardableResult public func calculateRoutes(options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) -> NavigationProviderRequest? {
        return calculate(options, completionHandler: completionHandler)
    }
    
    @discardableResult public func calculateRoutes(options: MatchOptions, completionHandler: @escaping MatchCompletionHandler) -> NavigationProviderRequest? {
        return calculate(options, completionHandler: completionHandler)
    }
    
    @discardableResult public func refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex: UInt32, completionHandler: @escaping RouteCompletionHandler) -> NavigationProviderRequest? {
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
        
        return refreshRoute(responseIdentifier: responseIdentifier,
                            routeIndex: indexedRouteResponse.routeIndex,
                            fromLegAtIndex: Int(fromLegAtIndex),
                            completionHandler: { credentials, result in
                                switch result {
                                case .failure(let error):
                                    DispatchQueue.main.async {
                                        completionHandler(session, .failure(error))
                                    }
                                case .success(let routeRefreshResponse):
                                    DispatchQueue.global().async {
                                        do {
                                            let routeResponse = try indexedRouteResponse.routeResponse.copy(with: routeOptions)
                                            routeResponse.routes?[indexedRouteResponse.routeIndex].refreshLegAttributes(from: routeRefreshResponse.route)
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
                            })
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
