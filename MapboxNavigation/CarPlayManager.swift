#if canImport(CarPlay)
import CarPlay
import Turf
import MapboxCoreNavigation
import MapboxDirections

@available(iOS 12.0, *)
@objc(MBCarPlayManagerDelegate)
public protocol CarPlayManagerDelegate {
    @objc(leadingNavigationBarButtonsWithTraitCollection:)
    func leadingNavigationBarButtons(compatibleWith traitCollection: UITraitCollection) -> [CPBarButton]?

    @objc(trailingNavigationBarButtonsWithTraitCollection:)
    func trailingNavigationBarButtons(compatibleWith traitCollection: UITraitCollection) -> [CPBarButton]?
}

@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject, CPInterfaceControllerDelegate, CPSearchTemplateDelegate {

    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?
    public fileprivate(set) var routeController: RouteController?

    /**
     * Developers should assign their own object as a delegate implementing the CarPlayManagerDelegate protocol for customization
     */
    public weak var delegate: CarPlayManagerDelegate?

    public static var shared = CarPlayManager()

    public static func resetSharedInstance() {
        shared = CarPlayManager()
    }
    
    var edgePadding: UIEdgeInsets {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return .zero
        }
        
        let padding:CGFloat = 15
        return UIEdgeInsets(top: carPlayMapViewController.mapView.safeAreaInsets.top + padding,
                            left: carPlayMapViewController.mapView.safeAreaInsets.left + padding,
                            bottom: carPlayMapViewController.mapView.safeAreaInsets.bottom + padding,
                            right: carPlayMapViewController.mapView.safeAreaInsets.right + padding)
    }

    enum CPFavoritesList {

        enum POI: RawRepresentable {
            typealias RawValue = String
            case mapboxSF, timesSquare

            var subTitle: String {
                switch self {
                case .mapboxSF:
                    return "Office Location"
                case .timesSquare:
                    return "Downtown Attractions"
                }
            }

            var location: CLLocation {
                switch self {
                case .mapboxSF:
                    return CLLocation(latitude: 37.7820776, longitude: -122.4155262)
                case .timesSquare:
                    return CLLocation(latitude: 40.758899, longitude: -73.9873197)
                }
            }
            
            var rawValue: String {
                switch self {
                case .mapboxSF:
                    return "Mapbox SF"
                case .timesSquare:
                    return "Times Square"
                }
            }
            
            init?(rawValue: String) {
                let value = rawValue.lowercased()
                switch value {
                case "mapbox sf":
                    self = .mapboxSF
                case "times square":
                    self = .timesSquare
                default:
                    return nil
                }
            }
        }
    }

    // MARK: CPApplicationDelegate

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        //TODO: event
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window
        
        let traitCollection = viewController.traitCollection

        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        if let leadingButtons = delegate?.leadingNavigationBarButtons(compatibleWith: traitCollection) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        } else {
            let searchTemplate = CPSearchTemplate()
            searchTemplate.delegate = self

            let searchButton = searchTemplateButton(searchTemplate: searchTemplate, interfaceController: interfaceController, traitCollection: traitCollection)
            mapTemplate.leadingNavigationBarButtons = [searchButton]
        }

        if let trailingButtons = delegate?.trailingNavigationBarButtons(compatibleWith: traitCollection) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        } else {
            let favoriteButton = favoriteTemplateButton(interfaceController: interfaceController, traitCollection: traitCollection)

            mapTemplate.trailingNavigationBarButtons = [favoriteButton]
        }

        mapTemplate.mapButtons = [viewController.zoomInButton(), viewController.zoomOutButton(), viewController.panButton(mapTemplate: mapTemplate)]
        
        interfaceController.setRootTemplate(mapTemplate, animated: false)
    }

    public func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        self.interfaceController = nil
        carWindow?.isHidden = true
    }

    // MARK: CPSearchTemplateDelegate

    private func cannedResults() -> Array<(String, CLLocationCoordinate2D)> {
        let nobHill: (String, CLLocationCoordinate2D) = ("Nob Hill", CLLocationCoordinate2D(latitude: 37.7910, longitude: -122.4131))
        return [nobHill]
    }

    public func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        // TODO: autocomplete immediately based on Favorites; calls to the search/geocoding client might require a minimum number of characters before firing
        // Results passed into this completionHandler will be displayed directly on the search template. Might want to limit the results set based on available screen real estate after testing.
    }

    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        // TODO: based on this callback we should push a CPListTemplate with a longer list of results.
        // Need to coordinate delegation of list item selection from this template vs items displayed directly in the search template
    }

    public func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {

    }

    private func searchTemplateButton(searchTemplate: CPSearchTemplate, interfaceController: CPInterfaceController, traitCollection: UITraitCollection) -> CPBarButton {
        
        let searchTemplateButton = CPBarButton(type: .image) { button in
            interfaceController.pushTemplate(searchTemplate, animated: true)
        }

        let bundle = Bundle.mapboxNavigation
        searchTemplateButton.image = UIImage(named: "search-monocle", in: bundle, compatibleWith: traitCollection)
        
        return searchTemplateButton
    }
    
    public func favoriteTemplateButton(interfaceController: CPInterfaceController, traitCollection: UITraitCollection) -> CPBarButton {
        
        let favoriteTemplateButton = CPBarButton(type: .image) { button in
            // TODO: Show List Template
            let mapboxSFItem = CPListItem(text: CPFavoritesList.POI.mapboxSF.rawValue,
                                    detailText: CPFavoritesList.POI.mapboxSF.subTitle)
            let timesSquareItem = CPListItem(text: CPFavoritesList.POI.timesSquare.rawValue,
                                       detailText: CPFavoritesList.POI.timesSquare.subTitle)
            let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])
            let listTemplate = CPListTemplate(title: "Favorites List", sections: [listSection])
            
            listTemplate.delegate = self
            
            interfaceController.pushTemplate(listTemplate, animated: true)
        }

        let bundle = Bundle.mapboxNavigation
        favoriteTemplateButton.image = UIImage(named: "star", in: bundle, compatibleWith: traitCollection)
        
        return favoriteTemplateButton
    }
}

// MARK: CPListTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPListTemplateDelegate {
    public func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        guard let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let mapTemplate = self.interfaceController?.rootTemplate as? CPMapTemplate else {
            return
        }
        let mapView = rootViewController.mapView
        
        guard let rawValue = item.text,
            let userLocation = mapView.userLocation?.location,
            let favoritePOI = CPFavoritesList.POI(rawValue: rawValue),
            let interfaceController = interfaceController else {
            return
        }
        interfaceController.popToRootTemplate(animated: false)
        
        let waypoints = [
            Waypoint(location: userLocation, heading: mapView.userLocation?.heading, name: "Current Location"),
            Waypoint(location: favoritePOI.location, heading: nil, name: favoritePOI.rawValue),
        ]
        let routeOptions = NavigationRouteOptions(waypoints: waypoints)
        Directions.shared.calculate(routeOptions) { [weak mapTemplate] (waypoints, routes, error) in
            guard let mapTemplate = mapTemplate, let waypoints = waypoints, let routes = routes else {
                return
            }
            
            if let error = error {
                let okAction = CPAlertAction(title: "OK", style: .default) { _ in
                    interfaceController.popToRootTemplate(animated: true)
                }
                let alert = CPNavigationAlert(titleVariants: [error.localizedDescription],
                                              subtitleVariants: [error.localizedFailureReason ?? ""],
                                              imageSet: nil,
                                              primaryAction: okAction,
                                              secondaryAction: nil,
                                              duration: 0)
                mapTemplate.present(navigationAlert: alert, animated: true)
                return
            }
            
            let briefDateComponentsFormatter = DateComponentsFormatter()
            briefDateComponentsFormatter.unitsStyle = .brief
            briefDateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
            let abbreviatedDateComponentsFormatter = DateComponentsFormatter()
            abbreviatedDateComponentsFormatter.unitsStyle = .abbreviated
            abbreviatedDateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
            
            var routeChoices: [CPRouteChoice] = []
            for (i, route) in routes.enumerated() {
                let additionalInformationVariants: [String]
                if i == 0 {
                    additionalInformationVariants = ["Fastest Route"]
                } else {
                    let delay = route.expectedTravelTime - routes.first!.expectedTravelTime
                    let briefDelay = briefDateComponentsFormatter.string(from: delay)!
                    let abbreviatedDelay = abbreviatedDateComponentsFormatter.string(from: delay)!
                    additionalInformationVariants = ["\(briefDelay) Slower", "+\(abbreviatedDelay)"]
                }
                let routeChoice = CPRouteChoice(summaryVariants: [route.description], additionalInformationVariants: additionalInformationVariants, selectionSummaryVariants: [])
                routeChoice.userInfo = route
                routeChoices.append(routeChoice)
            }
            
            let originPlacemark = MKPlacemark(coordinate: waypoints.first!.coordinate)
            let destinationPlacemark = MKPlacemark(coordinate: waypoints.last!.coordinate, addressDictionary: ["street": favoritePOI.subTitle])
            let trip = CPTrip(origin: MKMapItem(placemark: originPlacemark), destination: MKMapItem(placemark: destinationPlacemark), routeChoices: routeChoices)
            trip.userInfo = routeOptions
            
            let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: "Go", additionalRoutesButtonTitle: "Routes", overviewButtonTitle: "Overview")
            
            mapTemplate.showTripPreviews([trip], textConfiguration: defaultPreviewText)
            completionHandler()
        }
    }
}

// MARK: CPMapTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPMapTemplateDelegate {
    public func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let interfaceController = interfaceController,
            let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        
        mapTemplate.hideTripPreviews()
        let navigationSession = mapTemplate.startNavigationSession(for: trip)
        let routeController = RouteController(along: routeChoice.userInfo as! Route)
        let carPlayNavigationViewController = CarPlayNavigationViewController(for: routeController,
                                                                              session: navigationSession,
                                                                              template: mapTemplate,
                                                                              interfaceController: interfaceController)
        carPlayNavigationViewController.carPlayNavigationDelegate = self
        carPlayMapViewController.present(carPlayNavigationViewController, animated: true, completion: nil)
        
//        if let appViewFromCarPlayWindow = appViewFromCarPlayWindow {
//            navigationViewController.isUsedInConjunctionWithCarPlayWindow = true
//            appViewFromCarPlayWindow.present(navigationViewController, animated: true)
//        }
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        
        let mapView = carPlayMapViewController.mapView
        let route = routeChoice.userInfo as! Route
        let line = MGLPolyline(coordinates: route.coordinates!, count: UInt(route.coordinates!.count))
        mapView.removeAnnotations(mapView.annotations ?? [])
        mapView.addAnnotation(line)
        let padding = UIEdgeInsets(top: carPlayMapViewController.view.safeAreaInsets.top + 10,
                                   left: carPlayMapViewController.view.safeAreaInsets.left + 10,
                                   bottom: carPlayMapViewController.view.safeAreaInsets.bottom + 10,
                                   right: carPlayMapViewController.view.safeAreaInsets.right + 10)
        mapView.showAnnotations([line], edgePadding: padding, animated: true)
        //        guard let routeIndex = trip.routeChoices.lastIndex(where: {$0 == routeChoice}), var routes = appViewFromCarPlayWindow?.routes else { return }
        //        let route = routes[routeIndex]
        //        guard let foundRoute = routes.firstIndex(where: {$0 == route}) else { return }
        //        routes.remove(at: foundRoute)
        //        routes.insert(route, at: 0)
        //        appViewFromCarPlayWindow?.routes = routes
    }
    
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        // TODO: Shows panning interface
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        carPlayMapViewController.mapView.userTrackingMode = .follow
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        
        // TODO: Move mapview along the direction
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController, let userLocation = carPlayMapViewController.mapView.userLocation?.coordinate, let coordinates = self.routeController?.routeProgress.route.coordinates else {
            return
        }
        
        var panDirection = Double.infinity
        
        switch direction {
        case CPMapTemplate.PanDirection.right:
            panDirection = 90
        case CPMapTemplate.PanDirection.down:
            panDirection = 180
        case CPMapTemplate.PanDirection.left:
            panDirection = 270
        default:
            panDirection = 0
        }
        
        let nearestLocation = userLocation.coordinate(at: 20, facing: panDirection)
        let newLocation = CLLocationCoordinate2DMake(nearestLocation.latitude, nearestLocation.longitude)
        
        carPlayMapViewController.mapView.setOverheadCameraView(from: newLocation, along: coordinates, for: edgePadding)
    }
    
    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        carPlayMapViewController.mapView.userTrackingMode = .none
    }
}

@available(iOS 12.0, *)
extension CarPlayManager: CarPlayNavigationDelegate {
    public func carPlaynavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool) {
        carPlayNavigationViewController.carInterfaceController.popToRootTemplate(animated: true)
    }
}
#endif
