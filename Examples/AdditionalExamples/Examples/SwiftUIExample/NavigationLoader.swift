import CoreLocation
import MapboxNavigationCore

enum NavigationLoaderError: Error {
    case unknownLocation
}

struct NavigationLoader {
    let mapboxNavigation: MapboxNavigationProvider

    func requestRoutes(to destination: CLLocationCoordinate2D) async throws -> NavigationRoutes {
        guard let location = await mapboxNavigation.navigation().currentLocationMatching?.enhancedLocation else {
            throw NavigationLoaderError.unknownLocation
        }

        let options = NavigationRouteOptions(coordinates: [location.coordinate, destination])
        let result = await mapboxNavigation.mapboxNavigation.routingProvider()
            .calculateRoutes(options: options)
            .result

        return switch result {
        case .failure(let error):
            throw error
        case .success(let routes):
            routes
        }
    }
}
