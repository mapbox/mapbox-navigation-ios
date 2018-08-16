#if canImport(CarPlay)
import CarPlay
import Turf
import MapboxCoreNavigation

@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject, CPInterfaceControllerDelegate, CPSearchTemplateDelegate {

    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?
    public fileprivate(set) var routeController: RouteController?

    private static var privateShared: CarPlayManager?

    public static func shared() -> CarPlayManager {
        if let shared = privateShared {
            return shared
        }
        let shared = CarPlayManager()
        privateShared = shared
        return shared
    }

    public static func resetSharedInstance() {
        privateShared = nil
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
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let searchTemplate = CPSearchTemplate()
        searchTemplate.delegate = self

        let searchButton = searchTemplateButton(searchTemplate: searchTemplate, interfaceController: interfaceController)
        let favoriteButton = favoriteTemplateButton(interfaceController: interfaceController)
        
        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window
        
        mapTemplate.leadingNavigationBarButtons = [searchButton]
        mapTemplate.trailingNavigationBarButtons = [favoriteButton]
        mapTemplate.mapButtons = [viewController.zoomInButton(), viewController.zoomOutButton(), viewController.panButton(mapTemplate: mapTemplate)]
        
        interfaceController.setRootTemplate(mapTemplate, animated: false)
        interfaceController.delegate = self
        self.interfaceController = interfaceController
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

    public func searchTemplateButton(searchTemplate: CPSearchTemplate, interfaceController: CPInterfaceController) -> CPBarButton {
        
        let searchTemplateButton = CPBarButton(type: .image) { button in
            interfaceController.pushTemplate(searchTemplate, animated: true)
        }
        
        searchTemplateButton.image = Bundle.mapboxNavigation.image(named: "search-monocle")
        
        return searchTemplateButton
    }
    
    public func favoriteTemplateButton(interfaceController: CPInterfaceController) -> CPBarButton {
        
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
        
        favoriteTemplateButton.image = Bundle.mapboxNavigation.image(named: "star")
        
        return favoriteTemplateButton
    }
}

// MARK: CPListTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPListTemplateDelegate {
    public func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        
        if let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController, let mapTemplate = self.interfaceController?.rootTemplate as? CPMapTemplate {
            let mapView = rootViewController.mapView
            let userLocation = mapView.userLocation
            let originLocation = CLLocationCoordinate2D(latitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude)

            if let rawValue = item.text, let favoritePOI = CPFavoritesList.POI(rawValue: rawValue), let interfaceController = interfaceController {
                interfaceController.popToRootTemplate(animated: false)
                
                let mapboxSFTrip: CPTrip = self.trip(from: originLocation, to: favoritePOI.location.coordinate, destinationNickname: favoritePOI.rawValue)
                let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: "Let's GO!", additionalRoutesButtonTitle: "Directions Overview", overviewButtonTitle: "Take me Back.")
                
                mapTemplate.showTripPreviews([mapboxSFTrip], textConfiguration: defaultPreviewText)
                completionHandler()
            }
        }
    }
    
    private func trip(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, destinationNickname: String) -> CPTrip {
        let routeChoice = CPRouteChoice(summaryVariants: ["Fastest Route"],
                          additionalInformationVariants: ["Traffic is light."],
                               selectionSummaryVariants: ["Ready to navigate."])
        
        let trip = CPTrip(origin: MKMapItem(placemark: MKPlacemark(coordinate: origin)),
                     destination: MKMapItem(placemark: MKPlacemark(coordinate: destination,
                                    addressDictionary: ["street": destinationNickname])),
                    routeChoices: [routeChoice])
        
        return trip
    }
}

// MARK: CPMapTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPMapTemplateDelegate {
    public func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
//        startBasicNavigation()
        mapTemplate.hideTripPreviews()
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        //        guard let routeIndex = trip.routeChoices.lastIndex(where: {$0 == routeChoice}), var routes = appViewFromCarPlayWindow?.routes else { return }
        //        let route = routes[routeIndex]
        //        guard let foundRoute = routes.firstIndex(where: {$0 == route}) else { return }
        //        routes.remove(at: foundRoute)
        //        routes.insert(route, at: 0)
        //        appViewFromCarPlayWindow?.routes = routes
//        let textConfiguration = CPTripPreviewTextConfiguration.init(startButtonTitle: "Let's GO!", additionalRoutesButtonTitle: "Meh, show me more", overviewButtonTitle: "Take me Back")
//        mapTemplate.showRouteChoicesPreview(for: trip, textConfiguration: textConfiguration)
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
#endif
