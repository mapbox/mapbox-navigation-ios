import UIKit
import MapboxNavigation
#if canImport(CarPlay)
import CarPlay
import MapboxCoreNavigation
import MapboxDirections
#endif

/**
 This example application delegate implementation is used in both our "Example-Swift" and our "Example-CarPlay" example apps.

 In order to run the "Example-CarPlay" example app with CarPlay functionality enabled, one must first obtain a CarPlay entitlement from Apple.

 Once the entitlement has been obtained and loaded into your ADC account:
  - Create a provisioning profile which includes the entitlement
  - Download and select the provisioning profile for the "Example-CarPlay" example app
  - Be sure to select an iOS simulator or device running iOS 12 or greater
 **/
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    #if canImport(CarPlay)
    var simulatesLocationsInCarPlay = false
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if isRunningTests() {
            window!.rootViewController = UIViewController()
        }
        return true
    }

    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
}

#if canImport(CarPlay)
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
        let navigationViewControllerExistsInStack = UIViewController.viewControllerInStack(of: NavigationViewController.self) != nil
        
        if navigationViewControllerExistsInStack {
            if let navigationViewController = UIViewController.viewControllerInStack(of: NavigationViewController.self) {
                navigationViewController.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPBarButton]? {
        guard let template = template as? CPListTemplate, template.title == "Favorites List" else {
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
            return RouteController(along: route, locationManager: locationManager)
        } else {
            return RouteController(along: route)
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        return CarPlayGeocoder.searchTemplate(searchTemplate, updatedSearchText: searchText, completionHandler: completionHandler)
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        return CarPlayGeocoder.carPlayManager(searchTemplate, selectedResult: item, completionHandler: completionHandler)
    }
}
#endif
