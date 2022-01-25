import Foundation
import Network
import MapboxDirections
import MapboxNavigationNative

extension Directions {
    
    /**
     Begins asynchronously calculating routes using the given options and delivers the results to a closure.
     
     This method retrieves the routes asynchronously from the [Mapbox Directions API](https://www.mapbox.com/api-documentation/navigation/#directions) over a network connection. If a  server error occurs, details about the error are passed into the given completion handler in lieu of the routes. If network error is encountered, onboard routing engine will attempt to provide directions using existing cached tiles.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel this task.
     */
    @discardableResult open func calculateWithCache(options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) -> URLSessionDataTask? {
        return calculate(options) { (session, result) in
            switch result {
            case .success(_):
                completionHandler(session, result)
            case .failure(let error):
                if case DirectionsError.network(_) = error {
                    // we're offline
                    self.calculateOffline(options: options, completionHandler: completionHandler)
                } else {
                    completionHandler(session, result)
                }
            }
            
        }
    }
    
    /**
     Begins asynchronously calculating routes using the given options and delivers the results to a closure.
     
     This method retrieves the routes asynchronously from onboard routing engine using existing cached tiles.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     */
    open func calculateOffline(options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) {
        MapboxRoutingProvider(.offline).calculateRoutes(options: options,
                                                        completionHandler: completionHandler)
    }
}
