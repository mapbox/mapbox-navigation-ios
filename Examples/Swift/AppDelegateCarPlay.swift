import UIKit
import MapboxNavigation
#if canImport(CarPlay)
import CarPlay
import MapboxCoreNavigation
import MapboxDirections


@available(iOS 12.0, *)
extension AppDelegate: CPApplicationDelegate {
    
    // MARK: CPApplicationDelegate
    
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        CarPlayManager.shared.delegate = self
        CarPlayManager.shared.application(application, didConnectCarInterfaceController: interfaceController, to: window)
    }
    
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        CarPlayManager.shared.delegate = nil
        CarPlayManager.shared.application(application, didDisconnectCarInterfaceController: interfaceController, from: window)
    }
}

@available(iOS 12.0, *)
extension AppDelegate: CarPlayManagerDelegate {
    
    // MARK: CarPlayManagerDelegate
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith routeController: RouteController) {
        guard let presentingController = window?.rootViewController else { return }
        
        // Open StepsViewController on iPhone if NavigationViewController is being presented
        if let navigationViewController = presentingController as? NavigationViewController {
            navigationViewController.openStepsViewController()
        } else {
            
            // Start NavigationViewController and open StepsViewController if navigation has not started on iPhone yet.
            let navigationViewControllerExistsInStack = UIViewController.viewControllerInStack(of: NavigationViewController.self) != nil
            
            if !navigationViewControllerExistsInStack {
                
                let locationManager = routeController.locationManager
                let directions = routeController.directions
                let route = routeController.routeProgress.route
                let navigationViewController = NavigationViewController(for: route, directions: directions, locationManager: locationManager)
                
                presentingController.present(navigationViewController, animated: true, completion: {
                    navigationViewController.openStepsViewController()
                })
            }
        }
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        // Dismiss NavigationViewController if it's present in the navigation stack
        if let navigationViewController = UIViewController.viewControllerInStack(of: NavigationViewController.self) {
            navigationViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        guard activity == .previewing else {
            return nil
        }
        
        let simulationButton = CPBarButton(type: .text) { [weak self] (barButton) in
            guard let self = self else {
                return
            }
            
            self.simulatesLocationsInCarPlay = !self.simulatesLocationsInCarPlay
            barButton.title = self.simulatesLocationsInCarPlay ? "Don’t Simulate" : "Simulate"
            
        }
        simulationButton.title = self.simulatesLocationsInCarPlay ? "Don’t Simulate" : "Simulate"
        return [simulationButton]
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, routeControllerAlong route: Route) -> RouteController {
        if simulatesLocationsInCarPlay {
            let locationManager = SimulatedLocationManager(route: route)
            locationManager.speedMultiplier = 5
            return RouteController(along: route, locationManager: locationManager, eventsManager: carPlayManager.eventsManager)
        } else {
            return RouteController(along: route, eventsManager: carPlayManager.eventsManager)
        }
    }
    
    #if canImport(MapboxGeocoder)
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        return CarPlayManager.searchTemplate(searchTemplate, updatedSearchText: searchText, completionHandler: completionHandler)
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        return CarPlayManager.carPlayManager(searchTemplate, selectedResult: item, completionHandler: completionHandler)
    }
    #endif
}
#endif
