#if canImport(CarPlay)
import CarPlay
import Turf
import MapboxCoreNavigation
import MapboxDirections
import MapboxMobileEvents

@available(iOS 12.0, *)
@objc(MBCarPlayManagerDelegate)
public protocol CarPlayManagerDelegate {

    /**
     * Offers the delegate an opportunity to provide a customized list of leading bar buttons.
     *
     * These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     */
    @objc(carPlayManager:leadingNavigationBarButtonsWithTraitCollection:inTemplate:)
    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPBarButton]?

    /**
     * Offers the delegate an opportunity to provide a customized list of trailing bar buttons.
     *
     * These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     */
    @objc(carPlayManager:trailingNavigationBarButtonsWithTraitCollection:inTemplate:)
    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPBarButton]?
    
    /**
     * Offers the delegate an opportunity to provide a customized list of buttons displayed on the map.
     *
     * These buttons handle the gestures on the map view, so it is up to the developer to ensure the map template is interactive.
     */
    @objc(carPlayManager:mapButtonsCompatibleWithTraitCollection:inTemplate:)
    func carPlayManager(_ carplayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPMapButton]?

    /**
     * Offers the delegate an opportunity to provide an alternate navigator, otherwise a default built-in RouteController will be created and used.
     */
    @objc(carPlayManager:routeControllerAlongRoute:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, routeControllerAlong route: Route) -> RouteController
    
    
    @objc(carPlayManager:searchTemplate:updatedSearchText:completionHandler:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void)
    
    @objc(carPlayManager:searchTemplate:selectedResult:completionHandler:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void)
//}
//
//@available(iOS 12.0, *)
//@objc(MBCarPlayManagerNavigationDelegate)
//public protocol CarPlayManagerNavigationDelegate {

    /***/
    @objc(carPlayManager:didBeginNavigationWithRouteProgress:)
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith progress: RouteProgress) -> ()

    /***/
    @objc func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) -> ()

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

    public fileprivate(set) weak var currentNavigator: CarPlayNavigationViewController?

    public static func resetSharedInstance() {
        shared = CarPlayManager()
    }
    
    private var defaultMapButtons: [CPMapButton]?
    
    /**
     * This property manages the relevant events recorded for telemetry analysis.
     */
    public var eventsManager = EventsManager()

    lazy var briefDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()
    
    lazy var abbreviatedDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    // MARK: CPApplicationDelegate

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        
        // WIP - For telemetry testing purposes
        // eventsManager.start()
        
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window
        
        let mapTemplate = createMapTemplate(for: interfaceController, viewController: viewController)
        
        interfaceController.setRootTemplate(mapTemplate, animated: false)
        
        let timestamp = Date().ISO8601
        sendCarPlayConnectEvent(timestamp)
    }

    func createMapTemplate(for interfaceController: CPInterfaceController, viewController: UIViewController) -> CPMapTemplate {
        
        let traitCollection = viewController.traitCollection
        
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        if let leadingButtons = delegate?.carPlayManager(self, leadingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        } else {
            let searchTemplate = CPSearchTemplate()
            searchTemplate.delegate = self

            let searchButton = searchTemplateButton(searchTemplate: searchTemplate, interfaceController: interfaceController, traitCollection: traitCollection)
            mapTemplate.leadingNavigationBarButtons = [searchButton]
        }

        if let trailingButtons = delegate?.carPlayManager(self, trailingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        } else {
            let favoriteButton = favoriteTemplateButton(interfaceController: interfaceController, traitCollection: traitCollection)
            mapTemplate.trailingNavigationBarButtons = [favoriteButton]
        }
        
        if let mapButtons = delegate?.carPlayManager(self, mapButtonsCompatibleWith: traitCollection, in: mapTemplate) {
            mapTemplate.mapButtons = mapButtons
        } else if let vc = viewController as? CarPlayMapViewController {
            mapTemplate.mapButtons = [vc.zoomInButton(), vc.zoomOutButton(), panMapButton(for: mapTemplate, traitCollection: traitCollection)]
        }
        
        return mapTemplate
    }
    
    func panMapButton(for mapTemplate: CPMapTemplate, traitCollection: UITraitCollection) -> CPMapButton {
        let panButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            
            if !mapTemplate.isPanningInterfaceVisible {
                strongSelf.defaultMapButtons = mapTemplate.mapButtons
                let closeButton = strongSelf.dismissPanButton(for: mapTemplate, traitCollection: traitCollection)
                mapTemplate.mapButtons = [closeButton]
                mapTemplate.showPanningInterface(animated: true)
            }
        }
        
        let bundle = Bundle.mapboxNavigation
        panButton.image = UIImage(named: "pan-map", in: bundle, compatibleWith: traitCollection)
        
        return panButton
    }
    
    func dismissPanButton(for mapTemplate: CPMapTemplate, traitCollection: UITraitCollection) -> CPMapButton {
        let closeButton = CPMapButton { [weak self] button in
            guard let strongSelf = self, let mapButtons = strongSelf.defaultMapButtons else {
                return
            }
            
            mapTemplate.mapButtons = mapButtons
            mapTemplate.dismissPanningInterface(animated: true)
        }
        
        let bundle = Bundle.mapboxNavigation
        closeButton.image = UIImage(named: "close", in: bundle, compatibleWith: traitCollection)
        
        return closeButton
    }
    
    func sendCarPlayConnectEvent(_ timestamp: String) {
        let dateCreatedAttribute = [MMEEventKeyCreated: timestamp]
        eventsManager.manager.enqueueEvent(withName: MMEventTypeCarplayConnect, attributes: dateCreatedAttribute)
        eventsManager.manager.flush()
    }
    
    func sendCarPlayDisconnectEvent(_ timestamp: String) {
        let dateCreatedAttribute = [MMEEventKeyCreated: timestamp]
        eventsManager.manager.enqueueEvent(withName: MMEventTypeCarplayDisconnect, attributes: dateCreatedAttribute)
        eventsManager.manager.flush()
    }

    public func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        self.interfaceController = nil
        carWindow?.isHidden = true
        let timestamp = Date().ISO8601
        sendCarPlayDisconnectEvent(timestamp)
    }

    // MARK: CPSearchTemplateDelegate

    public func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        let notImplementedItem = CPListItem(text: "Search not implemented", detailText: nil)
        delegate?.carPlayManager?(self, searchTemplate: searchTemplate, updatedSearchText: searchText, completionHandler: completionHandler)
            ?? completionHandler([notImplementedItem])
    }

    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        // TODO: based on this callback we should push a CPListTemplate with a longer list of results.
        // Need to coordinate delegation of list item selection from this template vs items displayed directly in the search template
    }

    public func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        delegate?.carPlayManager?(self, searchTemplate: searchTemplate, selectedResult: item, completionHandler: completionHandler)
    }
    
    private func searchTemplateButton(searchTemplate: CPSearchTemplate, interfaceController: CPInterfaceController, traitCollection: UITraitCollection) -> CPBarButton {
        
        let searchTemplateButton = CPBarButton(type: .image) { [weak self] button in
            guard let strongSelf = self else {
                return
            }
 
            if let mapTemplate = interfaceController.topTemplate as? CPMapTemplate {
                strongSelf.resetPanButtons(mapTemplate)
            }
            
            interfaceController.pushTemplate(searchTemplate, animated: true)
        }

        let bundle = Bundle.mapboxNavigation
        searchTemplateButton.image = UIImage(named: "search-monocle", in: bundle, compatibleWith: traitCollection)
        
        return searchTemplateButton
    }
    
    private func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        if mapTemplate.isPanningInterfaceVisible, let mapButtons = defaultMapButtons {
            mapTemplate.mapButtons = mapButtons
            mapTemplate.dismissPanningInterface(animated: false)
        }
    }
    
    public func favoriteTemplateButton(interfaceController: CPInterfaceController, traitCollection: UITraitCollection) -> CPBarButton {
        
        let favoriteTemplateButton = CPBarButton(type: .image) { [weak self] button in
            guard let strongSelf = self else {
                return
            }

            if let mapTemplate = interfaceController.topTemplate as? CPMapTemplate {
                strongSelf.resetPanButtons(mapTemplate)
            }

            let mapboxSFItem = CPListItem(text: CPFavoritesList.POI.mapboxSF.rawValue,
                                    detailText: CPFavoritesList.POI.mapboxSF.subTitle)
            let timesSquareItem = CPListItem(text: CPFavoritesList.POI.timesSquare.rawValue,
                                       detailText: CPFavoritesList.POI.timesSquare.subTitle)
            let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])
            let listTemplate = CPListTemplate(title: "Favorites List", sections: [listSection])
            if let leadingButtons = strongSelf.delegate?.carPlayManager(strongSelf, leadingNavigationBarButtonsCompatibleWith: traitCollection, in: listTemplate) {
                listTemplate.leadingNavigationBarButtons = leadingButtons
            }
            if let trailingButtons = strongSelf.delegate?.carPlayManager(strongSelf, trailingNavigationBarButtonsCompatibleWith: traitCollection, in: listTemplate) {
                listTemplate.trailingNavigationBarButtons = trailingButtons
            }
            
            listTemplate.delegate = strongSelf
            
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
//        guard let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
//            completionHandler()
//            return
//        }
        //let mapView = rootViewController.mapView
        
        guard let rawValue = item.text,
            let favoritePOI = CPFavoritesList.POI(rawValue: rawValue) else {
                completionHandler()
                return
        }
        
        let destinationWaypoint = Waypoint(location: favoritePOI.location, heading: nil, name: favoritePOI.rawValue)
        calculateRouteAndStart(to: destinationWaypoint, completionHandler: completionHandler)
    }
    
    public func calculateRouteAndStart(from fromWaypoint: Waypoint? = nil, to toWaypoint: Waypoint, completionHandler: @escaping () -> Void) {
        
        guard let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let mapTemplate = self.interfaceController?.rootTemplate as? CPMapTemplate,
            let userLocation = rootViewController.mapView.userLocation,
            let location = userLocation.location,
            let interfaceController = interfaceController else {
                completionHandler()
                return
        }
        
        let originWaypoint = fromWaypoint ?? Waypoint(location: location, heading: userLocation.heading, name: "Current Location")
        
        interfaceController.popToRootTemplate(animated: false)
        
        let routeOptions = NavigationRouteOptions(waypoints: [originWaypoint, toWaypoint])
        Directions.shared.calculate(routeOptions) { [weak self, weak mapTemplate] (waypoints, routes, error) in
            guard let `self` = self, let mapTemplate = mapTemplate, let waypoints = waypoints, let routes = routes else {
                completionHandler()
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
                // TODO: do we need to fire the completionHandler? retry mechanism?
                return
            }
            
            var routeChoices: [CPRouteChoice] = []
            for (i, route) in routes.enumerated() {
                let additionalInformationVariants: [String]
                if i == 0 {
                    additionalInformationVariants = ["Fastest Route"]
                } else {
                    let delay = route.expectedTravelTime - routes.first!.expectedTravelTime
                    let briefDelay = self.briefDateComponentsFormatter.string(from: delay)!
                    let abbreviatedDelay = self.abbreviatedDateComponentsFormatter.string(from: delay)!
                    additionalInformationVariants = ["\(briefDelay) Slower", "+\(abbreviatedDelay)"]
                }
                let routeChoice = CPRouteChoice(summaryVariants: [route.description], additionalInformationVariants: additionalInformationVariants, selectionSummaryVariants: [])
                routeChoice.userInfo = route
                routeChoices.append(routeChoice)
            }
            
            //let placemarks = waypoints.map { MKPlacemark(coordinate: $0.coordinate, addressDictionary: ["street": $0.name]) }
            let originPlacemark = MKPlacemark(coordinate: waypoints.first!.coordinate)
            let destinationPlacemark = MKPlacemark(coordinate: waypoints.last!.coordinate, addressDictionary: ["street": waypoints.last!.name ?? ""])
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
        
        // TODO: Allow the application to decide whether to simulate the route.
        let route = routeChoice.userInfo as! Route
        let routeController: RouteController
        if let routeControllerFromDelegate = delegate?.carPlayManager?(self, routeControllerAlong: route) {
            routeController = routeControllerFromDelegate
        } else {
            routeController = RouteController(along: route)
        }
        
        let carPlayNavigationViewController = CarPlayNavigationViewController(for: routeController,
                                                                              on: trip,
                                                                              templateController: NavigationMapTemplateController(mapTemplate: mapTemplate),
                                                                              interfaceController: interfaceController)
        carPlayNavigationViewController.carPlayNavigationDelegate = self
        self.currentNavigator = carPlayNavigationViewController

        carPlayMapViewController.present(carPlayNavigationViewController, animated: true, completion: nil)
        
        let mapView = carPlayMapViewController.mapView
        mapView.removeRoutes()
        mapView.removeWaypoints()
        
//        if let appViewFromCarPlayWindow = appViewFromCarPlayWindow {
//            navigationViewController.isUsedInConjunctionWithCarPlayWindow = true
//            appViewFromCarPlayWindow.present(navigationViewController, animated: true)
//        }

        if let delegate = delegate {
            delegate.carPlayManager(self, didBeginNavigationWith: routeController.routeProgress)
        }
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        
        let mapView = carPlayMapViewController.mapView
        let route = routeChoice.userInfo as! Route
        mapView.removeRoutes()
        mapView.removeWaypoints()
        mapView.showRoutes([route])
        mapView.showWaypoints(route)
        
        mapView.userTrackingMode = .none
        
        let padding = UIEdgeInsets(top: 10,
                                   left: carPlayMapViewController.view.safeAreaInsets.left + 20,
                                   bottom: carPlayMapViewController.view.safeAreaInsets.bottom + 10,
                                   right: carPlayMapViewController.view.safeAreaInsets.right + 10)
        let line = MGLPolyline(coordinates: route.coordinates!, count: UInt(route.coordinates!.count))
        let camera = mapView.cameraThatFitsShape(line, direction: 0, edgePadding: padding)
        mapView.setCamera(camera, animated: true)
        //        guard let routeIndex = trip.routeChoices.lastIndex(where: {$0 == routeChoice}), var routes = appViewFromCarPlayWindow?.routes else { return }
        //        let route = routes[routeIndex]
        //        guard let foundRoute = routes.firstIndex(where: {$0 == route}) else { return }
        //        routes.remove(at: foundRoute)
        //        routes.insert(route, at: 0)
        //        appViewFromCarPlayWindow?.routes = routes
    }
    
    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        mapTemplate.mapButtons.forEach { $0.isHidden = true }
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint) {
        // Not enough velocity to overcome friction
        guard sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y)) > 100 else {
            return
        }
        
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        
        let decelerationRate: CGFloat = 0.9
        let offset = CGPoint(x: velocity.x * decelerationRate / 4, y: velocity.y * decelerationRate / 4)
        
        let mapView = carPlayMapViewController.mapView
        mapView.userTrackingMode = .none
        
        if let toCamera = cameraShouldPan(to: offset, mapView: mapView) {
            mapView.setCamera(toCamera, animated: true)
        }
    }
    
    func cameraShouldPan(to endPoint: CGPoint, mapView: NavigationMapView) -> MGLMapCamera? {
        let mapView = mapView
        let camera = mapView.camera
        let centerPoint = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x - endPoint.x, y: centerPoint.y - endPoint.y)
        
        camera.centerCoordinate = mapView.convert(endCameraPoint, toCoordinateFrom: mapView)
        
        return camera
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        mapTemplate.mapButtons.forEach { $0.isHidden = false }
    }
    
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        carPlayMapViewController.mapView.userTrackingMode = .none
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        
        let mapView = carPlayMapViewController.mapView
        let camera = mapView.camera
        
        mapView.userTrackingMode = .none

        var facing: CLLocationDirection = 0.0
        
        if direction.contains(.right) {
            facing = 90
        } else if direction.contains(.down) {
            facing = 180
        } else if direction.contains(.left) {
            facing = 270
        }
        
        let newCenter = camera.centerCoordinate.coordinate(at: CarPlayMapViewPanningIncrement, facing: facing)
        camera.centerCoordinate = newCenter
        mapView.setCamera(camera, animated: true)
    }
    
    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        carPlayMapViewController.mapView.userTrackingMode = .follow
    }
}

@available(iOS 12.0, *)
extension CarPlayManager: CarPlayNavigationDelegate {
    public func carPlayNavigationViewControllerDidArrive(_: CarPlayNavigationViewController) {
        delegate?.carPlayManagerDidEndNavigation(self)
    }

    public func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool) {
        carPlayNavigationViewController.carInterfaceController.popToRootTemplate(animated: true)
        delegate?.carPlayManagerDidEndNavigation(self)
    }
}
#endif
