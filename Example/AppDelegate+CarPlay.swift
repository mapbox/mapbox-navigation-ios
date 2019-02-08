import UIKit
import MapboxNavigation
#if canImport(CarPlay)
import CarPlay
import MapboxCoreNavigation
import MapboxDirections


/**
 This example application delegate implementation is used in both our "Example-Swift" and our "Example-CarPlay" example apps.
 
 In order to run the "Example-CarPlay" example app with CarPlay functionality enabled, one must first obtain a CarPlay entitlement from Apple.
 
 Once the entitlement has been obtained and loaded into your ADC account:
 - Create a provisioning profile which includes the entitlement
 - Download and select the provisioning profile for the "Example-CarPlay" example app
 - Be sure to select an iOS simulator or device running iOS 12 or greater
 */
@available(iOS 12.0, *)
extension AppDelegate: CPApplicationDelegate {
    
    // MARK: CPApplicationDelegate
    
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        carPlayManager.delegate = self
        carPlaySearchController.delegate = self
        carPlayManager.application(application, didConnectCarInterfaceController: interfaceController, to: window)
    }
    
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        carPlayManager.delegate = nil
        carPlaySearchController.delegate = nil
        carPlayManager.application(application, didDisconnectCarInterfaceController: interfaceController, from: window)
    }
}

@available(iOS 12.0, *)
extension AppDelegate: CarPlayManagerDelegate {
    
    // MARK: CarPlayManagerDelegate
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        guard let window = self.window else { return }
        NavigationViewController.carPlayManager(carPlayManager, didBeginNavigationWith: service, window: window)
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        // Dismiss NavigationViewController if it's present in the navigation stack
        guard let window = window else { return }
        NavigationViewController.carPlayManagerDidEndNavigation(carPlayManager, window: window)
    }
    
    func favoritesListTemplate() -> CPListTemplate {
        let mapboxSFItem = CPListItem(text: FavoritesList.POI.mapboxSF.rawValue,
                                      detailText: FavoritesList.POI.mapboxSF.subTitle)
        let timesSquareItem = CPListItem(text: FavoritesList.POI.timesSquare.rawValue,
                                         detailText: FavoritesList.POI.timesSquare.subTitle)
        mapboxSFItem.userInfo = [CarPlayManager.CarPlayWaypointKey: Waypoint(location: FavoritesList.POI.mapboxSF.location)]
        timesSquareItem.userInfo = [CarPlayManager.CarPlayWaypointKey: Waypoint(location: FavoritesList.POI.timesSquare.location)]
        let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])
        return CPListTemplate(title: "Favorites List", sections: [listSection])
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        
        guard let interfaceController = self.carPlayManager.interfaceController else {
            return nil
        }
        
        switch activity {
        case .browsing:
            let searchTemplate = CPSearchTemplate()
            searchTemplate.delegate = carPlaySearchController
            let searchButton = carPlaySearchController.searchTemplateButton(searchTemplate: searchTemplate, interfaceController: interfaceController, traitCollection: traitCollection)
            return [searchButton]
        case .navigating, .previewing, .panningInBrowsingMode:
            return nil
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        
        switch activity {
        case .previewing:
            let disableSimulateText = "Disable Simulation"
            let enableSimulateText =  "Enable Simulation"
            let simulationButton = CPBarButton(type: .text) { (barButton) in
                carPlayManager.simulatesLocations = !carPlayManager.simulatesLocations
                barButton.title = carPlayManager.simulatesLocations ? disableSimulateText : enableSimulateText
            }
            simulationButton.title = carPlayManager.simulatesLocations ? disableSimulateText : enableSimulateText
            return [simulationButton]
        case .browsing:
            let favoriteTemplateButton = CPBarButton(type: .image) { [weak self] button in
                guard let strongSelf = self else { return }
                let listTemplate = strongSelf.favoritesListTemplate()
                listTemplate.delegate = strongSelf
                carPlayManager.interfaceController?.pushTemplate(listTemplate, animated: true)
            }
            favoriteTemplateButton.image = UIImage(named: "carplay_star", in: nil, compatibleWith: traitCollection)
            return [favoriteTemplateButton]
        case .navigating, .panningInBrowsingMode:
            return nil
        }
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]? {
        
        switch activity {
        case .browsing:
            guard let mapViewController = carPlayManager.carPlayMapViewController,
                  let mapTemplate = template as? CPMapTemplate else {
                return nil
            }
            var mapButtons = [mapViewController.recenterButton,
                              mapViewController.zoomInButton,
                              mapViewController.zoomOutButton]
            mapButtons.insert(mapViewController.panningInterfaceDisplayButton(for: mapTemplate), at: 1)
            return mapButtons
        case .previewing, .navigating, .panningInBrowsingMode:
            return nil
        }
    }
}

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

@available(iOS 12.0, *)
extension AppDelegate: CPListTemplateDelegate {
    
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        // Selected a favorite
        if let userInfo = item.userInfo as? [String: Any],
            let waypoint = userInfo[CarPlayManager.CarPlayWaypointKey] as? Waypoint {
            carPlayManager.previewRoutes(to: waypoint, completionHandler: completionHandler)
            return
        }
        
        completionHandler()
    }
}
#endif
