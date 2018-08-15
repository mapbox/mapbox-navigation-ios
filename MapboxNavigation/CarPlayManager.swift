#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject, CPInterfaceControllerDelegate, CPSearchTemplateDelegate {

    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?

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

    private enum CPFavoritesList {

        enum POI {
            case mapboxSF, timesSquare

            var description: String {
                switch self {
                case .mapboxSF:
                    return "Mapbox SF"
                case .timesSquare:
                    return "Times Square"
                }
            }

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
        }
    }

    // MARK: CPApplicationDelegate

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        let mapTemplate = CPMapTemplate()

        let searchTemplate = CPSearchTemplate()
        searchTemplate.delegate = self

        let searchButton: CPBarButton = CPBarButton(type: .image) { button in
            interfaceController.pushTemplate(searchTemplate, animated: true)
        }
        
        let favoriteButton: CPBarButton = CPBarButton(type: .image) { button in
            let mapboxSFItem = CPListItem(text: CPFavoritesList.POI.mapboxSF.description, detailText: CPFavoritesList.POI.mapboxSF.subTitle)
            let timesSquareItem = CPListItem(text: CPFavoritesList.POI.timesSquare.description, detailText: CPFavoritesList.POI.timesSquare.subTitle)
            let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])
            let listTemplate = CPListTemplate(title: "Favorites List", sections: [listSection])
            listTemplate.delegate = self
            interfaceController.pushTemplate(listTemplate, animated: true)
        }
        
        
        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window
        
        searchButton.image = UIImage(named: "search-monocle", in: .mapboxNavigation, compatibleWith: nil)
        favoriteButton.image = UIImage(named: "star", in: .mapboxNavigation, compatibleWith: nil)
        
        mapTemplate.leadingNavigationBarButtons = [searchButton]
        mapTemplate.trailingNavigationBarButtons = [favoriteButton]
        mapTemplate.mapButtons = [viewController.zoomInButton(), viewController.zoomOutButton()]
        mapTemplate.mapDelegate = self
        
        interfaceController.setRootTemplate(mapTemplate, animated: false)
        interfaceController.delegate = self
        self.interfaceController = interfaceController
    }
    
    private func trip(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CPTrip {
        let routeChoice = CPRouteChoice(summaryVariants: ["Fastest Route"], additionalInformationVariants: ["Traffic is light."], selectionSummaryVariants: ["N/A"])
        
        let trip = CPTrip(origin: MKMapItem(placemark: MKPlacemark(coordinate: origin)), destination: MKMapItem(placemark: MKPlacemark(coordinate: destination)), routeChoices: [routeChoice])
        return trip
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

    public func searchButton() -> CPBarButton {
        let searchButton = CPBarButton(type: .image) { button in
            // TODO: Show Map Template
        }
        searchButton.image = Bundle.mapboxNavigation.image(named: "search-monocle")
        return searchButton
    }
    
    public static func favoriteButton() -> CPBarButton {
        let favoriteButton = CPBarButton(type: .image) { button in
            // TODO: Show List Template
        }
        favoriteButton.image = Bundle.mapboxNavigation.image(named: "star")
        return favoriteButton
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

            let mapboxSFLocation = CLLocationCoordinate2D(latitude: 37.7820776, longitude: -122.4155262)
            let timesSquareLocation = CLLocationCoordinate2D(latitude: 40.758899, longitude: -73.9873197)

            let mapboxSFTrip = self.trip(from: originLocation, to: mapboxSFLocation)
            let timesSquareTrip = self.trip(from: originLocation, to: timesSquareLocation)

            let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: "Go", additionalRoutesButtonTitle: "Addition Routes", overviewButtonTitle: "Overview")
            
            // TODO: Dismiss list before displaying the trip previews
            
            mapTemplate.showTripPreviews([mapboxSFTrip, timesSquareTrip], textConfiguration: defaultPreviewText)
            
            completionHandler()
        }
    }
}

// MARK: CPMapTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPMapTemplateDelegate {
    public func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
//        startBasicNavigation()
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        //        guard let routeIndex = trip.routeChoices.lastIndex(where: {$0 == routeChoice}), var routes = appViewFromCarPlayWindow?.routes else { return }
        //        let route = routes[routeIndex]
        //        guard let foundRoute = routes.firstIndex(where: {$0 == route}) else { return }
        //        routes.remove(at: foundRoute)
        //        routes.insert(route, at: 0)
        //        appViewFromCarPlayWindow?.routes = routes
        let textConfiguration = CPTripPreviewTextConfiguration.init(startButtonTitle: "Let's GO!", additionalRoutesButtonTitle: "Meh, show me more", overviewButtonTitle: "Take me Back")
        mapTemplate.showRouteChoicesPreview(for: trip, textConfiguration: textConfiguration)
    }
}
#endif
