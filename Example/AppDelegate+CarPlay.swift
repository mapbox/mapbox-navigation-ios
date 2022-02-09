import UIKit
import MapboxNavigation
import CarPlay
import MapboxGeocoder
import MapboxCoreNavigation
import MapboxDirections

let CarPlayWaypointKey: String = "MBCarPlayWaypoint"

extension NavigationGeocodedPlacemark {
    /**
     Initializes a newly created `NavigationGeocodedPlacemark` object with a `GeocodedPlacemark`
     instance and an optional subtitle.
     
     - parameter geocodedPlacemark: A `GeocodedPlacemark` instance, properties of which will be used in
     `NavigationGeocodedPlacemark`.
     - parameter subtitle: Subtitle, which can contain additional information regarding placemark
     (e.g. address).
     */
    init(geocodedPlacemark: GeocodedPlacemark, subtitle: String?) {
        self.init(title: geocodedPlacemark.formattedName, subtitle: subtitle, location: geocodedPlacemark.location, routableLocations: geocodedPlacemark.routableLocations)
    }
}

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
                        navigationServiceFor routeResponse: RouteResponse,
                        routeIndex: Int,
                        routeOptions: RouteOptions,
                        desiredSimulationMode: SimulationMode) -> NavigationService? {
        if let navigationViewController = self.window?.rootViewController?.presentedViewController as? NavigationViewController,
           let navigationService = navigationViewController.navigationService {
            // Do not set simulation mode if we already have an active navigation session.
            return navigationService
        }
        
        return MapboxNavigationService(routeResponse: routeResponse,
                                       routeIndex: routeIndex,
                                       routeOptions: routeOptions,
                                       routingProvider: MapboxRoutingProvider(.hybrid),
                                       credentials: NavigationSettings.shared.directions.credentials,
                                       simulating: desiredSimulationMode)
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, didPresent navigationViewController: CarPlayNavigationViewController) {
        currentAppRootViewController?.beginNavigationWithCarPlay(navigationService: navigationViewController.navigationService)
        navigationViewController.compassView.isHidden = false
        
        // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
        navigationViewController.routeLineTracksTraversal = true
        navigationViewController.navigationMapView?.showsRestrictedAreasOnRoute = true
        
        // Example of building highlighting in 3D.
        navigationViewController.waypointStyle = .extrudedBuilding
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager,
                                        byCanceling canceled: Bool) {
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
        case .navigating, .previewing, .panningInBrowsingMode, .panningInNavigationMode:
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
        
        let title = NSLocalizedString("CARPLAY_FAVORITES_LIST",
                                      bundle: .main,
                                      value: "Favorites List",
                                      comment: "CPListTemplate title, which shows list of favorite destinations")
        
        return CPListTemplate(title: title, sections: [listSection])
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in template: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        switch activity {
        case .previewing:
            let disableSimulateText = NSLocalizedString("CARPLAY_DISABLE_SIMULATION",
                                                        bundle: .main,
                                                        value: "Disable Simulation",
                                                        comment: "CPBarButton title, which allows to disable location simulation")
            
            let enableSimulateText = NSLocalizedString("CARPLAY_ENABLE_SIMULATION",
                                                       bundle: .main,
                                                       value: "Enable Simulation",
                                                       comment: "CPBarButton title, which allows to enable location simulation")
            
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
        case .navigating, .panningInBrowsingMode, .panningInNavigationMode:
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
            
            let mapButtons = [
                carPlayMapViewController.recenterButton,
                carPlayMapViewController.panningInterfaceDisplayButton(for: mapTemplate),
                carPlayMapViewController.zoomInButton,
                carPlayMapViewController.zoomOutButton
            ]
            
            return mapButtons
        case .previewing, .navigating, .panningInBrowsingMode, .panningInNavigationMode:
            return nil
        }
    }
}

// MARK: - CarPlaySearchControllerDelegate methods

@available(iOS 12.0, *)
extension AppDelegate: CarPlaySearchControllerDelegate {
    
    struct MaximumSearchResults {
        static var initial: UInt = 5
        static var extended: UInt = 10
    }
    
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
        carPlayManager.interfaceController?.safePopTemplate(animated: animated)
    }
    
    func forwardGeocodeOptions(_ searchText: String) -> ForwardGeocodeOptions {
        let options = ForwardGeocodeOptions(query: searchText)
        options.focalLocation = AppDelegate.coarseLocationManager.location
        options.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
        var allScopes: PlacemarkScope = .all
        allScopes.remove(.postalCode)
        options.allowedScopes = allScopes
        options.maximumResultCount = MaximumSearchResults.extended
        options.includesRoutableLocations = true
        
        return options
    }
    
    func recentSearches(with searchText: String) -> [CPListItem] {
        if searchText.isEmpty {
            return recentItems.map { $0.navigationGeocodedPlacemark.listItem() }
        }
        
        return recentItems.filter {
            $0.matches(searchText)
        }.map {
            $0.navigationGeocodedPlacemark.listItem()
        }
    }
    
    func searchResults(with items: [CPListItem], limit: UInt?) -> [CPListItem] {
        recentSearchItems = items
        
        if items.count > 0 {
            if let limit = limit {
                return Array<CPListItem>(items.prefix(Int(limit)))
            }
            
            return items
        } else {
            let title = NSLocalizedString("CARPLAY_SEARCH_NO_RESULTS",
                                          bundle: .mapboxNavigation,
                                          value: "No results",
                                          comment: "Message when search returned zero results in CarPlay")
            
            let noResultListItem = CPListItem(text: title,
                                              detailText: nil,
                                              image: nil,
                                              showsDisclosureIndicator: false)
            
            return [noResultListItem]
        }
    }
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        updatedSearchText searchText: String,
                        completionHandler: @escaping ([CPListItem]) -> Void) {
        recentSearchText = searchText
        
        var items = recentSearches(with: searchText)
        let limit = MaximumSearchResults.initial
        
        // Search for placemarks using MapboxGeocoder.swift
        let shouldSearch = searchText.count > 2
        if shouldSearch {
            let options = forwardGeocodeOptions(searchText)
            Geocoder.shared.geocode(options, completionHandler: { [weak self] (placemarks, attribution, error) in
                guard let self = self else {
                    completionHandler([])
                    return
                }
                
                guard let placemarks = placemarks else {
                    completionHandler(self.searchResults(with: items, limit: limit))
                    return
                }
                
                let navigationGeocodedPlacemarks = placemarks.map {
                    NavigationGeocodedPlacemark(geocodedPlacemark: $0, subtitle: $0.subtitle)
                }
                
                let results = navigationGeocodedPlacemarks.map { $0.listItem() }
                items.append(contentsOf: results)
                completionHandler(self.searchResults(with: results, limit: limit))
            })
        } else {
            completionHandler(self.searchResults(with: items, limit: limit))
        }
    }
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        selectedResult item: CPListItem,
                        completionHandler: @escaping () -> Void) {
        guard let userInfo = item.userInfo as? CarPlayUserInfo,
              let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark,
              let location = placemark.routableLocations?.first ?? placemark.location else {
            completionHandler()
            return
        }
        
        recentItems.add(RecentItem(placemark))
        recentItems.save()
        
        let destinationWaypoint = Waypoint(location: location,
                                           heading: nil,
                                           name: placemark.title)
        previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
}

extension GeocodedPlacemark {
    
    var subtitle: String? {
        if let addressDictionary = addressDictionary,
           var lines = addressDictionary["formattedAddressLines"] as? [String] {
            // Chinese addresses have no commas and are reversed.
            if scope == .address {
                if qualifiedName?.contains(", ") ?? false {
                    lines.removeFirst()
                } else {
                    lines.removeLast()
                }
            }
            
            let separator = NSLocalizedString("ADDRESS_LINE_SEPARATOR",
                                              value: ", ",
                                              comment: "Delimiter between lines in an address when displayed inline")
            
            if let regionCode = administrativeRegion?.code,
               let abbreviatedRegion = regionCode.components(separatedBy: "-").last,
               (abbreviatedRegion as NSString).intValue == 0 {
                // Cut off country and postal code and add abbreviated state/region code at the end.
                
                let subtitle = lines.prefix(2).joined(separator: separator)
                
                let scopes: PlacemarkScope = [
                    .region,
                    .district,
                    .place,
                    .postalCode
                ]
                
                if scopes.contains(scope) {
                    return subtitle
                }
                
                return subtitle.appending("\(separator)\(abbreviatedRegion)")
            }
            
            if scope == .country {
                return ""
            }
            
            if qualifiedName?.contains(", ") ?? false {
                return lines.joined(separator: separator)
            }
            
            return lines.joined()
        }
        
        return description
    }
}

// MARK: - CPListTemplateDelegate methods

@available(iOS 12.0, *)
extension AppDelegate: CPListTemplateDelegate {
    
    func listTemplate(_ listTemplate: CPListTemplate,
                      didSelect item: CPListItem,
                      completionHandler: @escaping () -> Void) {
        // Selected a list item for the list of favorites.
        guard let userInfo = item.userInfo as? CarPlayUserInfo,
              let waypoint = userInfo[CarPlayWaypointKey] as? Waypoint else {
                  completionHandler()
                  return
              }
        
        carPlayManager.previewRoutes(to: waypoint, completionHandler: completionHandler)
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
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        appDelegate.carPlayManager.delegate = nil
        appDelegate.carPlaySearchController.delegate = nil
        
        if let navigationViewController = appDelegate.currentAppRootViewController?.activeNavigationViewController {
            navigationViewController.didDisconnectFromCarPlay()
        }
        
        appDelegate.carPlayManager.templateApplicationScene(templateApplicationScene,
                                                            didDisconnectCarInterfaceController: interfaceController,
                                                            from: window)
    }
}
