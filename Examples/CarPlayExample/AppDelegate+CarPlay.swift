import CarPlay
import MapboxDirections
import MapboxGeocoder
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

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
        self.init(
            title: geocodedPlacemark.formattedName,
            subtitle: subtitle,
            location: geocodedPlacemark.location,
            routableLocations: geocodedPlacemark.routableLocations
        )
    }
}

// MARK: - CPTemplateApplicationSceneDelegate methods

/**
 This example application delegate implementation is used for "Example-CarPlay" target.

 In order to run the "Example-CarPlay" example app with CarPlay functionality enabled, one must first obtain a CarPlay entitlement from Apple.

 Once the entitlement has been obtained and loaded into your ADC account:
 - Create a provisioning profile which includes the entitlement
 - Download and select the provisioning profile for the "Example-CarPlay" example app
 - Be sure to select an iOS simulator or device running iOS 14 or greater
 */

// MARK: - CarPlaySceneDelegate methods

class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        appDelegate.carPlayManager.delegate = appDelegate
        appDelegate.carPlaySearchController.delegate = appDelegate
        appDelegate.carPlayManager.templateApplicationScene(
            templateApplicationScene,
            didConnectCarInterfaceController: interfaceController,
            to: window
        )
        // NOTE: When CarPlay is connected, we check if there is an active navigation in progress and start CarPlay
        // navigation as well, otherwise, CarPlay will be in passive navigation and stay out of sync with iOS app.
        if appDelegate.currentAppRootViewController?.activeNavigationViewController != nil {
            appDelegate.currentAppRootViewController?.beginCarPlayNavigation()
        } else if let routes = appDelegate.currentAppRootViewController?.routes {
            Task {
                await appDelegate.carPlayManager.previewRoutes(for: routes)
            }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        appDelegate.carPlayManager.delegate = nil
        appDelegate.carPlaySearchController.delegate = nil

        if let navigationViewController = appDelegate.currentAppRootViewController?.activeNavigationViewController {
            navigationViewController.didDisconnectFromCarPlay()
        }

        appDelegate.carPlayManager.templateApplicationScene(
            templateApplicationScene,
            didDisconnectCarInterfaceController: interfaceController,
            from: window
        )
    }
}

// MARK: - CarPlayManagerDelegate methods

extension AppDelegate: CarPlayManagerDelegate {
    func carPlayManager(
        _ carPlayManager: MapboxNavigationUIKit.CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: MapboxNavigationUIKit.CarPlayActivity,
        cameraState: MapboxNavigationCore.NavigationCameraState
    ) -> [CPBarButton]? {
        return nil
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didSetup navigationMapView: NavigationMapView) {}

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        selectedPreviewFor trip: CPTrip,
        using routeChoice: CPRouteChoice
    ) {
        guard let routes = routeChoice.navigationRoutes, shouldPreviewRoutes(for: routes) else { return }
        currentAppRootViewController?.routes = routes
    }

    private func shouldPreviewRoutes(for routes: NavigationRoutes) -> Bool {
        guard let currentRoutes = currentAppRootViewController?.routes else {
            return true
        }
        return routes != currentRoutes
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        guidanceBackgroundColorFor style: UIUserInterfaceStyle
    ) -> UIColor? {
        #colorLiteral(red: 0.08061028272, green: 0.4138993621, blue: 0.8905753493, alpha: 1)
    }

    func carPlayManagerWillCancelPreview(
        _ carPlayManager: CarPlayManager,
        configuration: inout CarPlayManagerCancelPreviewConfiguration
    ) {
        configuration.popToRoot = true
    }

    func carPlayManagerDidCancelPreview(_ carPlayManager: CarPlayManager) {
        currentAppRootViewController?.routes = nil
    }

    func carPlayManagerDidBeginNavigation(_ carPlayManager: CarPlayManager) {
        if !(currentAppRootViewController?.presentedViewController is NavigationViewController) {
            currentAppRootViewController?.startBasicNavigation()
        }
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didPresent navigationViewController: CarPlayNavigationViewController
    ) {
        navigationViewController.compassView.isHidden = false

        // Render part of the route that has been traversed with full transparency, to give the illusion of a
        // disappearing route.
        navigationViewController.routeLineTracksTraversal = true
        navigationViewController.navigationMapView?.showsRestrictedAreasOnRoute = true

        guard let navigationMapView = navigationViewController.navigationMapView else { return }
        // Provide the custom layer position for route line in active navigation.
        guard let route = navigationProvider.mapboxNavigation.tripSession().currentNavigationRoutes else { return }
        navigationMapView.show(route, routeAnnotationKinds: [.relativeDurationsOnAlternative])
    }

    func carPlayManagerDidEndNavigation(
        _ carPlayManager: CarPlayManager,
        byCanceling canceled: Bool
    ) {
        // Dismiss NavigationViewController if it's present in the navigation stack
        navigationProvider.tripSession().setToIdle()
        currentAppRootViewController?.dismissActiveNavigationViewController()
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return true
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in template: CPMapTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        guard let interfaceController = self.carPlayManager.interfaceController else {
            return nil
        }

        switch activity {
        case .browsing:
            let searchTemplate = CPSearchTemplate()
            searchTemplate.delegate = carPlaySearchController
            let searchButton = carPlaySearchController.searchTemplateButton(
                searchTemplate: searchTemplate,
                interfaceController: interfaceController,
                traitCollection: traitCollection
            )
            return [searchButton]
        case .navigating, .previewing, .panningInBrowsingMode, .panningInNavigationMode:
            return nil
        }
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didFailToFetchRouteBetween waypoints: [Waypoint]?,
        options: RouteOptions,
        error: Error
    ) -> CPNavigationAlert? {
        let title = NSLocalizedString(
            "CARPLAY_OK",
            bundle: .main,
            value: "OK",
            comment: "CPAlertTemplate OK button title"
        )

        let action = CPAlertAction(
            title: title,
            style: .default,
            handler: { _ in }
        )

        let alert = CPNavigationAlert(
            titleVariants: [error.localizedDescription],
            subtitleVariants: [],
            image: nil,
            primaryAction: action,
            secondaryAction: nil,
            duration: 5
        )
        return alert
    }

    func favoritesListTemplate() -> CPListTemplate {
        let mapboxSFItem = CPListItem(
            text: FavoritesList.POI.mapboxSF.rawValue,
            detailText: FavoritesList.POI.mapboxSF.subTitle
        )
        mapboxSFItem.handler = { [weak self] _, completion in
            guard let self else { completion(); return }
            let waypoint = Waypoint(location: FavoritesList.POI.mapboxSF.location)
            carPlayManager.previewRoutes(to: waypoint, completionHandler: completion)
        }

        let timesSquareItem = CPListItem(
            text: FavoritesList.POI.timesSquare.rawValue,
            detailText: FavoritesList.POI.timesSquare.subTitle
        )
        timesSquareItem.handler = { [weak self] _, completion in
            guard let self else { completion(); return }
            let waypoint = Waypoint(location: FavoritesList.POI.timesSquare.location)
            carPlayManager.previewRoutes(to: waypoint, completionHandler: completion)
        }

        let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])

        let title = NSLocalizedString(
            "CARPLAY_FAVORITES_LIST",
            bundle: .main,
            value: "Favorites List",
            comment: "CPListTemplate title, which shows list of favorite destinations"
        )

        return CPListTemplate(title: title, sections: [listSection])
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in template: CPMapTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        switch activity {
        case .browsing:
            let configuration = UIImage.SymbolConfiguration(pointSize: 24)
            let image = UIImage(systemName: "star.fill", withConfiguration: configuration) ?? UIImage()

            let favoriteTemplateButton = CPBarButton(image: image) { [weak self] _ in
                guard let self else { return }
                let listTemplate = favoritesListTemplate()
                carPlayManager.interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
            }

            return [favoriteTemplateButton]
        case .navigating, .panningInBrowsingMode, .panningInNavigationMode, .previewing:
            return nil
        }
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        mapButtonsCompatibleWith traitCollection: UITraitCollection,
        in template: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPMapButton]? {
        switch activity {
        case .browsing:
            guard let carPlayMapViewController = carPlayManager.carPlayMapViewController,
                  let mapTemplate = template as? CPMapTemplate
            else {
                return nil
            }

            let mapButtons = [
                carPlayMapViewController.recenterButton,
                carPlayMapViewController.panningInterfaceDisplayButton(for: mapTemplate),
                carPlayMapViewController.zoomInButton,
                carPlayMapViewController.zoomOutButton,
            ]

            return mapButtons
        case .previewing, .navigating, .panningInBrowsingMode, .panningInNavigationMode:
            return nil
        }
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldShowNotificationFor maneuver: CPManeuver,
        in mapTemplate: CPMapTemplate
    ) -> Bool {
        return true
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldShowNotificationFor navigationAlert: CPNavigationAlert,
        in mapTemplate: CPMapTemplate
    ) -> Bool {
        return true
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldUpdateNotificationFor maneuver: CPManeuver,
        with travelEstimates: CPTravelEstimates,
        in mapTemplate: CPMapTemplate
    ) -> Bool {
        return true
    }
}

// MARK: - CarPlaySearchControllerDelegate methods

extension AppDelegate: CarPlaySearchControllerDelegate {
    enum MaximumSearchResults {
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
        carPlayManager.interfaceController?.pushTemplate(template, animated: animated, completion: nil)
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
            if let limit {
                return [CPListItem](items.prefix(Int(limit)))
            }

            return items
        } else {
            let title = NSLocalizedString(
                "CARPLAY_SEARCH_NO_RESULTS",
                bundle: .mapboxNavigation,
                value: "No results",
                comment: "Message when search returned zero results in CarPlay"
            )

            let noResultListItem = CPListItem(
                text: title,
                detailText: nil,
                image: nil
            )
            return [noResultListItem]
        }
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    ) {
        recentSearchText = searchText

        var items = recentSearches(with: searchText)
        let limit = MaximumSearchResults.initial

        // Search for placemarks using MapboxGeocoder.swift
        let shouldSearch = searchText.count > 2
        if shouldSearch {
            let options = forwardGeocodeOptions(searchText)
            Geocoder.shared.geocode(options, completionHandler: { [weak self] placemarks, _, _ in
                guard let self else {
                    completionHandler([])
                    return
                }

                guard let placemarks else {
                    completionHandler(searchResults(with: items, limit: limit))
                    return
                }

                let navigationGeocodedPlacemarks = placemarks.map {
                    NavigationGeocodedPlacemark(geocodedPlacemark: $0, subtitle: $0.subtitle)
                }

                let results = navigationGeocodedPlacemarks.map { $0.listItem() }
                items.append(contentsOf: results)
                completionHandler(searchResults(with: results, limit: limit))
            })
        } else {
            completionHandler(searchResults(with: items, limit: limit))
        }
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        guard let userInfo = item.userInfo as? CarPlayUserInfo,
              let placemark =
              userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark,
              let location = placemark.routableLocations?.first ?? placemark.location
        else {
            completionHandler()
            return
        }

        recentItems.add(RecentItem(placemark))
        recentItems.save()

        let destinationWaypoint = Waypoint(
            location: location,
            heading: nil,
            name: placemark.title
        )
        previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
}

extension GeocodedPlacemark {
    var subtitle: String? {
        if let addressDictionary,
           var lines = addressDictionary["formattedAddressLines"] as? [String]
        {
            // Chinese addresses have no commas and are reversed.
            if scope == .address {
                if qualifiedName?.contains(", ") ?? false {
                    lines.removeFirst()
                } else {
                    lines.removeLast()
                }
            }

            let separator = NSLocalizedString(
                "ADDRESS_LINE_SEPARATOR",
                value: ", ",
                comment: "Delimiter between lines in an address when displayed inline"
            )

            if let regionCode = administrativeRegion?.code,
               let abbreviatedRegion = regionCode.components(separatedBy: "-").last,
               (abbreviatedRegion as NSString).intValue == 0
            {
                // Cut off country and postal code and add abbreviated state/region code at the end.

                let subtitle = lines.prefix(2).joined(separator: separator)

                let scopes: PlacemarkScope = [
                    .region,
                    .district,
                    .place,
                    .postalCode,
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
