#if canImport(CarPlay)
import CarPlay
import Turf
import MapboxCoreNavigation
import MapboxDirections
import MapboxMobileEvents

/**
 The activity during which a `CPTemplate` is displayed. This enumeration is used to distinguish between different templates during different phases of user interaction.
 */
@available(iOS 12.0, *)
@objc(MBCarPlayActivity)
public enum CarPlayActivity: Int {
    /// The user is browsing the map or searching for a destination.
    case browsing
    /// The user is previewing a route or selecting among multiple routes.
    case previewing
    /// The user is actively navigating along a route.
    case navigating
}

@available(iOS 12.0, *)
@objc(MBCarPlayManagerDelegate)
public protocol CarPlayManagerDelegate {

    /**
     * Offers the delegate an opportunity to provide a customized list of leading bar buttons.
     *
     * These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     * If this method is not implemented, or if nil is returned, an implementation of CPSearchTemplate will be provided which uses the Mapbox Geocoder.
     */
    @objc(carPlayManager:leadingNavigationBarButtonsWithTraitCollection:inTemplate:forActivity:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]?

    /**
     * Offers the delegate an opportunity to provide a customized list of trailing bar buttons.
     *
     * These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     */
    @objc(carPlayManager:trailingNavigationBarButtonsWithTraitCollection:inTemplate:forActivity:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]?

    /**
     * Offers the delegate an opportunity to provide a customized list of buttons displayed on the map.
     *
     * These buttons handle the gestures on the map view, so it is up to the developer to ensure the map template is interactive.
     * If this method is not implemented, or if nil is returned, a default set of zoom and pan buttons will be provided.
     */
    @objc(carPlayManager:mapButtonsCompatibleWithTraitCollection:inTemplate:forActivity:)
    optional func carPlayManager(_ carplayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]?

    /**
     * Offers the delegate an opportunity to provide an alternate navigator, otherwise a default built-in RouteController will be created and used.
     */
    @objc(carPlayManager:routeControllerAlongRoute:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, routeControllerAlong route: Route) -> RouteController

    /**
     * Offers the delegate an opportunity to react to updates in the search text.
     */
    @objc(carPlayManager:searchTemplate:updatedSearchText:completionHandler:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void)

    /**
     * Offers the delegate an opportunity to react to selection of a search result.
     */
    @objc(carPlayManager:searchTemplate:selectedResult:completionHandler:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void)
//}
//
//@available(iOS 12.0, *)
//@objc(MBCarPlayManagerNavigationDelegate)
//public protocol CarPlayManagerNavigationDelegate {

    /**
     * Called when navigation begins so that the containing app can update accordingly.
     */
    @objc(carPlayManager:didBeginNavigationWithRouteController:)
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith routeController: RouteController) -> ()

    /**
     * Called when navigation ends so that the containing app can update accordingly.
     */
    @objc func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) -> ()

    /**
     Called when the carplay manager will disable the idle timer.

     Implementing this method will allow developers to change whether idle timer is disabled when carplay is connected and the vice-versa when disconnected.

     - parameter carPlayManager: The carplay manager that will change the state of idle timer.
     - returns: A bool indicating whether to disable idle timer when carplay is connected and enable when disconnected.
     */
    @objc optional func carplayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool

}

@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject {

    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?
    public fileprivate(set) var routeController: RouteController?

    /**
     * Developers should assign their own object as a delegate implementing the CarPlayManagerDelegate protocol for customization
     */
    public weak var delegate: CarPlayManagerDelegate?

    /**
     * If set to `true`, turn-by-turn directions will simulate the user traveling along the selected route when initiated from CarPlay
     */
    public var simulatesLocations = false

    /**
     * This property specifies a multiplier to be applied to the user's speed in simulation mode.
     */
    public var simulatedSpeedMultiplier = 1.0

    public static var shared = CarPlayManager()

    public fileprivate(set) var mainMapTemplate: CPMapTemplate?
    public fileprivate(set) weak var currentNavigator: CarPlayNavigationViewController?

    public static func resetSharedInstance() {
        shared = CarPlayManager()
    }

    private var defaultMapButtons: [CPMapButton]?

    /**
     A boolean value indicating whether the phone is connected to a CarPlay device or not.
     */
    public var isConnectedToCarPlay: Bool = false

    /**
     * This property manages the relevant events recorded for telemetry analysis.
     */
    public var eventsManager = EventsManager()

    lazy var fullDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    lazy var shortDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    lazy var briefDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    // MARK: CPApplicationDelegate

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {

        isConnectedToCarPlay = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        if let shouldDisableIdleTimer = delegate?.carplayManagerShouldDisableIdleTimer?(self) {
            UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window

        let mapTemplate = self.mapTemplate(for: interfaceController, viewController: viewController)
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false)

        let timestamp = Date().ISO8601
        sendCarPlayConnectEvent(timestamp)
    }

    func mapTemplate(for interfaceController: CPInterfaceController, viewController: UIViewController) -> CPMapTemplate {

        let traitCollection = viewController.traitCollection

        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        if let leadingButtons = delegate?.carPlayManager?(self, leadingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate, for: .browsing) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        } else {
            #if canImport(CarPlay) && canImport(MapboxGeocoder)
            let searchTemplate = CPSearchTemplate()
            searchTemplate.delegate = self

            let searchButton = searchTemplateButton(searchTemplate: searchTemplate, interfaceController: interfaceController, traitCollection: traitCollection)
            mapTemplate.leadingNavigationBarButtons = [searchButton]
            #endif
        }

        if let trailingButtons = delegate?.carPlayManager?(self, trailingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate, for: .browsing) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        } else {
            let favoriteButton = favoriteTemplateButton(interfaceController: interfaceController, traitCollection: traitCollection)
            mapTemplate.trailingNavigationBarButtons = [favoriteButton]
        }

        if let mapButtons = delegate?.carPlayManager?(self, mapButtonsCompatibleWith: traitCollection, in: mapTemplate, for: .browsing) {
            mapTemplate.mapButtons = mapButtons
        } else if let vc = viewController as? CarPlayMapViewController {
            mapTemplate.mapButtons = [vc.recenterButton, panMapButton(for: mapTemplate, traitCollection: traitCollection), vc.zoomInButton(), vc.zoomOutButton()]
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
        isConnectedToCarPlay = false
        self.interfaceController = nil
        carWindow?.isHidden = true
        let timestamp = Date().ISO8601
        sendCarPlayDisconnectEvent(timestamp)

        // Upon disconnecting the device from carplay, the idle timer ideally should be reset to its initial state.
        if let shouldDisableIdleTimer = delegate?.carplayManagerShouldDisableIdleTimer?(self) {
            UIApplication.shared.isIdleTimerDisabled = !shouldDisableIdleTimer
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func resetPanButtons(_ mapTemplate: CPMapTemplate) {
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
            if let leadingButtons = strongSelf.delegate?.carPlayManager?(strongSelf, leadingNavigationBarButtonsCompatibleWith: traitCollection, in: listTemplate, for: .browsing) {
                listTemplate.leadingNavigationBarButtons = leadingButtons
            }
            if let trailingButtons = strongSelf.delegate?.carPlayManager?(strongSelf, trailingNavigationBarButtonsCompatibleWith: traitCollection, in: listTemplate, for: .browsing) {
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

// MARK: CPInterfaceControllerDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPInterfaceControllerDelegate {
    public func templateWillAppear(_ template: CPTemplate, animated: Bool) {
        if template == interfaceController?.rootTemplate, let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
            carPlayMapViewController.recenterButton.isHidden = true
        }
    }
    
    public func templateDidAppear(_ template: CPTemplate, animated: Bool) {
        guard interfaceController?.topTemplate == mainMapTemplate else { return }
        if template == interfaceController?.rootTemplate, let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
            
            
            let mapView = carPlayMapViewController.mapView
            mapView.removeRoutes()
            mapView.removeWaypoints()
            mapView.setUserTrackingMode(.followWithCourse, animated: true)
        }
    }
    public func templateWillDisappear(_ template: CPTemplate, animated: Bool) {

        let isCorrectType = type(of: template) == CPSearchTemplate.self || type(of: template) == CPMapTemplate.self

        guard let interface = interfaceController, let top = interface.topTemplate,
            type(of: top) == CPSearchTemplate.self || interface.templates.count == 1,
            isCorrectType,
            let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController else { return }
            if type(of: template) == CPSearchTemplate.self {
                carPlayMapViewController.isOverviewingRoutes = false
            }
            carPlayMapViewController.resetCamera(animated: false)

    }
}

// MARK: CPListTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPListTemplateDelegate {

    public func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
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

        let routeOptions = NavigationRouteOptions(waypoints: [originWaypoint, toWaypoint])
        Directions.shared.calculate(routeOptions) { [weak self, weak mapTemplate] (waypoints, routes, error) in
            defer {
                completionHandler()
            }

            guard let `self` = self, let mapTemplate = mapTemplate else {
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
            }
            guard let waypoints = waypoints, let routes = routes else {
                return
            }

            let routeChoices = routes.map { (route) -> CPRouteChoice in
                let summaryVariants = [
                    self.fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                    self.shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                    self.briefDateComponentsFormatter.string(from: route.expectedTravelTime)!
                ]
                let routeChoice = CPRouteChoice(summaryVariants: summaryVariants, additionalInformationVariants: [route.description], selectionSummaryVariants: [route.description])
                routeChoice.userInfo = route
                return routeChoice
            }

            //let placemarks = waypoints.map { MKPlacemark(coordinate: $0.coordinate, addressDictionary: ["street": $0.name]) }
            let originPlacemark = MKPlacemark(coordinate: waypoints.first!.coordinate)
            let destinationPlacemark = MKPlacemark(coordinate: waypoints.last!.coordinate, addressDictionary: ["street": waypoints.last!.name ?? ""])
            let trip = CPTrip(origin: MKMapItem(placemark: originPlacemark), destination: MKMapItem(placemark: destinationPlacemark), routeChoices: routeChoices)
            trip.userInfo = routeOptions

            let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: "Go", additionalRoutesButtonTitle: "More Routes", overviewButtonTitle: "Overview")

            let previewMapTemplate = self.mapTemplate(forPreviewing: trip)
            interfaceController.pushTemplate(previewMapTemplate, animated: true)

            previewMapTemplate.showTripPreviews([trip], textConfiguration: defaultPreviewText)
        }
    }

    func mapTemplate(forPreviewing trip: CPTrip) -> CPMapTemplate {
        let rootViewController = self.carWindow?.rootViewController as! CarPlayMapViewController
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self
        if let leadingButtons = delegate?.carPlayManager?(self, leadingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, in: mapTemplate, for: .previewing) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        if let trailingButtons = delegate?.carPlayManager?(self, trailingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, in: mapTemplate, for: .previewing) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        return mapTemplate
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

        let route = routeChoice.userInfo as! Route
        let routeController: RouteController
        if let routeControllerFromDelegate = delegate?.carPlayManager?(self, routeControllerAlong: route) {
            routeController = routeControllerFromDelegate
        } else {
            routeController = createRouteController(with: route)
        }

        interfaceController.popToRootTemplate(animated: false)
        let navigationMapTemplate = self.mapTemplate(forNavigating: trip)
        interfaceController.setRootTemplate(navigationMapTemplate, animated: true)

        let navigationViewController = CarPlayNavigationViewController(for: routeController,
                                                                       mapTemplate: navigationMapTemplate,
                                                                       interfaceController: interfaceController)
        navigationViewController.startNavigationSession(for: trip)
        navigationViewController.carPlayNavigationDelegate = self
        currentNavigator = navigationViewController
        
        carPlayMapViewController.isOverviewingRoutes = false
        carPlayMapViewController.present(navigationViewController, animated: true, completion: nil)

        let mapView = carPlayMapViewController.mapView
        mapView.removeRoutes()
        mapView.removeWaypoints()

        delegate?.carPlayManager(self, didBeginNavigationWith: routeController)
    }

    func mapTemplate(forNavigating trip: CPTrip) -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let showFeedbackButton = CPMapButton { [weak self] (button) in
            self?.currentNavigator?.showFeedback()
        }
        showFeedbackButton.image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)

        let overviewButton = CPMapButton { [weak self] (button) in
            guard let navigationViewController = self?.currentNavigator else {
                return
            }
            navigationViewController.tracksUserCourse = !navigationViewController.tracksUserCourse

            let imageName = navigationViewController.tracksUserCourse ? "overview" : "location"
            button.image = UIImage(named: imageName, in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        }
        overviewButton.image = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)

        mapTemplate.mapButtons = [overviewButton, showFeedbackButton]

        if let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let leadingButtons = delegate?.carPlayManager?(self, leadingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, in: mapTemplate, for: .navigating) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        let muteButton = CPBarButton(type: .text) { (button: CPBarButton) in
            NavigationSettings.shared.voiceMuted = !NavigationSettings.shared.voiceMuted
            button.title = NavigationSettings.shared.voiceMuted ? "Enable Voice" : "Disable Voice"
        }
        muteButton.title = NavigationSettings.shared.voiceMuted ? "Enable Voice" : "Disable Voice"
        mapTemplate.leadingNavigationBarButtons.insert(muteButton, at: 0)

        if let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let trailingButtons = delegate?.carPlayManager?(self, trailingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, in: mapTemplate, for: .navigating) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        let exitButton = CPBarButton(type: .text) { [weak self] (button: CPBarButton) in
            self?.currentNavigator?.exitNavigation(canceled: true)
        }
        exitButton.title = "End"
        mapTemplate.trailingNavigationBarButtons.append(exitButton)

        return mapTemplate
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        carPlayMapViewController.isOverviewingRoutes = true
        let mapView = carPlayMapViewController.mapView
        let route = routeChoice.userInfo as! Route
        
        
        
        //FIXME: Unable to tilt map during route selection -- https://github.com/mapbox/mapbox-gl-native/issues/2259
        let topDownCamera = mapView.camera
        topDownCamera.pitch = 0
        mapView.setCamera(topDownCamera, animated: false)

        let padding = NavigationMapView.defaultPadding + mapView.safeArea
        mapView.showcase([route], padding: padding)
    }

    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        let mapView = carPlayMapViewController.mapView
        mapView.removeRoutes()
        mapView.removeWaypoints()
        delegate?.carPlayManagerDidEndNavigation(self)
    }

    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        if let navigationViewController = currentNavigator, mapTemplate == navigationViewController.mapTemplate {
            navigationViewController.beginPanGesture()
        } else {
            mapTemplate.mapButtons.forEach { $0.isHidden = true }
        }
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint) {
        // Not enough velocity to overcome friction
        guard sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y)) > 100 else {
            return
        }

        let mapView: NavigationMapView
        if let navigationViewController = currentNavigator, mapTemplate == navigationViewController.mapTemplate {
            mapView = navigationViewController.mapView!
        } else if let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController {
            mapView = carPlayMapViewController.mapView
        } else {
            return
        }

        let decelerationRate: CGFloat = 0.9
        let offset = CGPoint(x: velocity.x * decelerationRate / 4, y: velocity.y * decelerationRate / 4)

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

    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }

        let mapView = carPlayMapViewController.mapView
        
        let contentFrame = UIEdgeInsetsInsetRect(mapView.bounds, mapView.safeArea)
        var center = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        let increment = min(mapView.bounds.width, mapView.bounds.height) / 2.0
        if direction.contains(.up) {
            center.y -= increment
        } else if direction.contains(.down) {
            center.y += increment
        } else if direction.contains(.left) {
            center.x -= increment
        } else if direction.contains(.right) {
            center.x += increment
        }
        
        let centerCoordinate = mapView.convert(center, toCoordinateFrom: mapView)
        mapView.setCenter(centerCoordinate, animated: true)
    }

    private func createRouteController(with route: Route) -> RouteController {
        if self.simulatesLocations {
            let locationManager = SimulatedLocationManager(route: route)
            locationManager.speedMultiplier = self.simulatedSpeedMultiplier
            return RouteController(along: route, locationManager: locationManager, eventsManager: eventsManager)
        } else {
            return RouteController(along: route, eventsManager: eventsManager)
        }
    }
}

@available(iOS 12.0, *)
extension CarPlayManager: CarPlayNavigationDelegate {
    public func carPlayNavigationViewControllerDidArrive(_: CarPlayNavigationViewController) {
        delegate?.carPlayManagerDidEndNavigation(self)
    }

    public func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool) {
        if let mainMapTemplate = mainMapTemplate {
            interfaceController?.setRootTemplate(mainMapTemplate, animated: true)
        }
        interfaceController?.popToRootTemplate(animated: true)
        delegate?.carPlayManagerDidEndNavigation(self)
    }
}
#else
@objc(MBCarPlayManager)
class CarPlayManager: NSObject {
    public static var shared = CarPlayManager()
    var isConnectedToCarPlay: Bool = false
}
#endif
