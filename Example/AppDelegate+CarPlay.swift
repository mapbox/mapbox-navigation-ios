import UIKit
import MapboxNavigation
import CarPlay
import MapboxCoreNavigation
import MapboxDirections

let CarPlayWaypointKey: String = "MBCarPlayWaypoint"

// MARK: - CPApplicationDelegate methods

/**
 This example application delegate implementation is used for "Example-CarPlay" target.
 
 In order to run the "Example-CarPlay" example app with CarPlay functionality enabled, one must first obtain a CarPlay entitlement from Apple.
 
 Once the entitlement has been obtained and loaded into your ADC account:
 - Create a provisioning profile which includes the entitlement
 - Download and select the provisioning profile for the "Example-CarPlay" example app
 - Be sure to select an iOS simulator or device running iOS 12 or greater
 */
@available(iOS 12.0, *)
extension AppDelegate: CPApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didConnectCarInterfaceController interfaceController: CPInterfaceController,
                     to window: CPWindow) {
        carPlayManager.delegate = self
        carPlaySearchController.delegate = self
        carPlayManager.application(application, didConnectCarInterfaceController: interfaceController, to: window)
        
        if let navigationViewController = self.window?.rootViewController?.presentedViewController as? NavigationViewController,
           let navigationService = navigationViewController.navigationService,
           let currentLocation = navigationService.router.location?.coordinate {
            carPlayManager.beginNavigationWithCarPlay(using: currentLocation, navigationService: navigationService)
        }
    }
    
    func application(_ application: UIApplication,
                     didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
                     from window: CPWindow) {
        carPlayManager.delegate = nil
        carPlaySearchController.delegate = nil
        carPlayManager.application(application, didDisconnectCarInterfaceController: interfaceController, from: window)
        
        if let navigationViewController = currentAppRootViewController?.activeNavigationViewController {
            navigationViewController.didDisconnectFromCarPlay()
        }
    }
}

// MARK: - CarPlayManagerDelegate methods

@available(iOS 12.0, *)
extension AppDelegate: CarPlayManagerDelegate {
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        navigationServiceAlong route: Route,
                        routeIndex: Int,
                        routeOptions: RouteOptions,
                        desiredSimulationMode: SimulationMode) -> NavigationService {
        if let navigationViewController = self.window?.rootViewController?.presentedViewController as? NavigationViewController,
           let navigationService = navigationViewController.navigationService {
            // Do not set simulation mode if we already have an active navigation session.
            return navigationService
        }
        
        return MapboxNavigationService(route: route,
                                       routeIndex: routeIndex,
                                       routeOptions: routeOptions,
                                       simulating: desiredSimulationMode)
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        currentAppRootViewController?.beginNavigationWithCarPlay(navigationService: service)
        carPlayManager.carPlayNavigationViewController?.compassView.isHidden = false
        
        // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
        carPlayManager.carPlayNavigationViewController?.routeLineTracksTraversal = true
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        // Dismiss NavigationViewController if it's present in the navigation stack
        currentAppRootViewController?.dismissActiveNavigationViewController()
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return true
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in template: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        guard let interfaceController = self.carPlayManager.interfaceController else {
            return nil
        }
        
        switch activity {
        case .browsing:
            let searchTemplate = CPSearchTemplate()
            searchTemplate.delegate = carPlaySearchController
            let searchButton = carPlaySearchController.searchTemplateButton(searchTemplate: searchTemplate,
                                                                            interfaceController: interfaceController,
                                                                            traitCollection: traitCollection)
            return [searchButton]
        case .navigating, .previewing, .panningInBrowsingMode:
            return nil
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didFailToFetchRouteBetween waypoints: [Waypoint]?,
                        options: RouteOptions,
                        error: DirectionsError) -> CPNavigationAlert? {
        let title = NSLocalizedString("CARPLAY_OK",
                                      bundle: .main,
                                      value: "OK",
                                      comment: "CPAlertTemplate OK button title")
        
        let action = CPAlertAction(title: title,
                                   style: .default,
                                   handler: { _ in })
        
        let alert = CPNavigationAlert(titleVariants: [error.localizedDescription],
                                      subtitleVariants: [error.failureReason ?? ""],
                                      imageSet: nil,
                                      primaryAction: action,
                                      secondaryAction: nil,
                                      duration: 5)
        return alert
    }
    
    func favoritesListTemplate() -> CPListTemplate {
        let mapboxSFItem = CPListItem(text: FavoritesList.POI.mapboxSF.rawValue,
                                      detailText: FavoritesList.POI.mapboxSF.subTitle)
        mapboxSFItem.userInfo = [
            CarPlayWaypointKey: Waypoint(location: FavoritesList.POI.mapboxSF.location)
        ]
        
        let timesSquareItem = CPListItem(text: FavoritesList.POI.timesSquare.rawValue,
                                         detailText: FavoritesList.POI.timesSquare.subTitle)
        timesSquareItem.userInfo = [
            CarPlayWaypointKey: Waypoint(location: FavoritesList.POI.timesSquare.location)
        ]
        
        let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])
        
        return CPListTemplate(title: "Favorites List", sections: [listSection])
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in template: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        switch activity {
        case .previewing:
            let disableSimulateText = "Disable Simulation"
            let enableSimulateText = "Enable Simulation"
            let simulationButton = CPBarButton(type: .text) { (barButton) in
                carPlayManager.simulatesLocations = !carPlayManager.simulatesLocations
                barButton.title = carPlayManager.simulatesLocations ? disableSimulateText : enableSimulateText
            }
            simulationButton.title = carPlayManager.simulatesLocations ? disableSimulateText : enableSimulateText
            return [simulationButton]
        case .browsing:
            let favoriteTemplateButton = CPBarButton(type: .image) { [weak self] button in
                guard let self = self else { return }
                let listTemplate = self.favoritesListTemplate()
                listTemplate.delegate = self
                carPlayManager.interfaceController?.pushTemplate(listTemplate, animated: true)
            }
            favoriteTemplateButton.image = UIImage(named: "carplay_star", in: nil, compatibleWith: traitCollection)
            return [favoriteTemplateButton]
        case .navigating, .panningInBrowsingMode:
            return nil
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        mapButtonsCompatibleWith traitCollection: UITraitCollection,
                        in template: CPTemplate,
                        for activity: CarPlayActivity) -> [CPMapButton]? {
        switch activity {
        case .browsing:
            guard let carPlayMapViewController = carPlayManager.carPlayMapViewController,
                let mapTemplate = template as? CPMapTemplate else {
                return nil
            }
            
            var mapButtons = [
                carPlayMapViewController.recenterButton,
                carPlayMapViewController.zoomInButton,
                carPlayMapViewController.zoomOutButton
            ]
            
            mapButtons.insert(carPlayMapViewController.panningInterfaceDisplayButton(for: mapTemplate), at: 1)
            return mapButtons
        case .previewing, .navigating, .panningInBrowsingMode:
            return nil
        }
    }
}

// MARK: - CarPlaySearchControllerDelegate methods

@available(iOS 12.0, *)
extension AppDelegate: CarPlaySearchControllerDelegate {
    
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void) {
        carPlayManager.previewRoutes(to: waypoint, completionHandler: completionHandler)
    }
    
    func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        carPlayManager.resetPanButtons(mapTemplate)
    }
    
    func pushTemplate(_ template: CPTemplate, animated: Bool) {
        if let listTemplate = template as? CPListTemplate {
            listTemplate.delegate = carPlaySearchController
        }
        carPlayManager.interfaceController?.pushTemplate(template, animated: animated)
    }
    
    func popTemplate(animated: Bool) {
        carPlayManager.interfaceController?.popTemplate(animated: animated)
    }
}

// MARK: - CPListTemplateDelegate methods

@available(iOS 12.0, *)
extension AppDelegate: CPListTemplateDelegate {
    
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        // Selected a favorite
        if let userInfo = item.userInfo as? [String: Any],
            let waypoint = userInfo[CarPlayWaypointKey] as? Waypoint {
            carPlayManager.previewRoutes(to: waypoint, completionHandler: completionHandler)
            return
        }
        
        completionHandler()
    }
}

// MARK: - CarPlaySceneDelegate methods

@available(iOS 13.0, *)
class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController,
                                  to window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = appDelegate
        appDelegate.carPlaySearchController.delegate = appDelegate
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didConnectCarInterfaceController: interfaceController,
                                                            to: window)
        
        appDelegate.carPlayManager.application(UIApplication.shared,
                                               didConnectCarInterfaceController: interfaceController,
                                               to: window)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = nil
        appDelegate.carPlaySearchController.delegate = nil
        appDelegate.carPlayManager.application(UIApplication.shared,
                                               didDisconnectCarInterfaceController: interfaceController,
                                               from: window)
        
        if let navigationViewController = appDelegate.currentAppRootViewController?.activeNavigationViewController {
            navigationViewController.didDisconnectFromCarPlay()
        }
        
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didDisconnectCarInterfaceController: interfaceController,
                                                            from: window)
    }
}
