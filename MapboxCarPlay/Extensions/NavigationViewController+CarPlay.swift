import CarPlay
import MapboxNavigation
import MapboxCoreNavigation

extension NavigationViewController {
    /**
     Presents a `NavigationViewController` on the top most view controller in the window and opens up the `StepsViewController`.
     If the `NavigationViewController` is already in the stack, it will open the `StepsViewController` unless it is already open.
     */
    @available(iOS 12.0, *)
    public class func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith navigationService: NavigationService, window: UIWindow) {
        
        if let navigationViewController = window.viewControllerInStack(of: NavigationViewController.self) {
            // Open StepsViewController on iPhone if NavigationViewController is being presented
            navigationViewController.isUsedInConjunctionWithCarPlayWindow = true
        } else {
            
            // Start NavigationViewController and open StepsViewController if navigation has not started on iPhone yet.
            let navigationViewControllerExistsInStack = window.viewControllerInStack(of: NavigationViewController.self) != nil
            
            if !navigationViewControllerExistsInStack {
                
                let directions = navigationService.directions
                let route = navigationService.routeProgress.route
                
                let service = MapboxNavigationService(route: route, directions: directions, simulating: navigationService.simulationMode)
                let navigationViewController = NavigationViewController(for: route, navigationService: service)
                
                window.rootViewController?.topMostViewController()?.present(navigationViewController, animated: true, completion: {
                    navigationViewController.isUsedInConjunctionWithCarPlayWindow = true
                })
            }
        }
    }
    
    /**
     Dismisses a `NavigationViewController` if there is any in the navigation stack.
     */
    @available(iOS 12.0, *)
    public class func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager, window: UIWindow) {
        if let navigationViewController = window.viewControllerInStack(of: NavigationViewController.self) {
            navigationViewController.dismiss(animated: true, completion: nil)
        }
    }
}
