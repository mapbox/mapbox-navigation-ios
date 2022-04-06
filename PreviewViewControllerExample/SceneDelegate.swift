import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var routeResponse: RouteResponse?
    
    var navigationRouteOptions: NavigationRouteOptions?
    
    var routeIndex: Int = 0
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let previewViewController = PreviewViewController()
        previewViewController.delegate = self
        window?.rootViewController = previewViewController
        window?.makeKeyAndVisible()
    }
}

extension SceneDelegate: PreviewViewControllerDelegate {
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateDidChangeTo state: PreviewViewController.State) {
        switch state {
        case .initial:
            routeIndex = 0
            break
        case .requested:
            break
        case .previewing:
            break
        }
    }
    
    func previewViewControllerDidBeginNavigation(_ previewViewController: PreviewViewController) {
        guard let routeResponse = routeResponse,
              let navigationRouteOptions = navigationRouteOptions else {
                  return
              }
        
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: routeIndex,
                                                        routeOptions: navigationRouteOptions,
                                                        routingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: .always)
        
        // TODO: Implement `NavigationMapView` injection.
        // let navigationOptions = NavigationOptions(navigationService: navigationService, navigationMapView: self.navigationView.navigationMapView)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: routeResponse,
                                                                   routeIndex: routeIndex,
                                                                   routeOptions: navigationRouteOptions,
                                                                   navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        window?.rootViewController?.present(navigationViewController, animated: false, completion: nil)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didLongPressFor coordinates: [CLLocationCoordinate2D]) {
        navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        Directions.shared.calculate(navigationRouteOptions!) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured: \(error.localizedDescription).")
            case .success(let routeResponse):
                guard let self = self else { return }
                
                self.routeResponse = routeResponse
                
                previewViewController.preview(routeResponse)
            }
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelectRouteAt index: Int,
                               from routeResponse: RouteResponse) {
        self.routeIndex = index
    }
}

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        navigationViewController.dismiss(animated: false, completion: nil)
    }
}
