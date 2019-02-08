#if canImport(CarPlay)
import CarPlay
import Turf
import MapboxCoreNavigation
import MapboxDirections

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

/**
 `CarPlayManager` is the main object responsible for orchestrating interactions with a Mapbox map on CarPlay.
 
 Messages declared in the `CPApplicationDelegate` protocol should be sent to this object in the containing application's application delegate. Implement `CarPlayManagerDelegate` in the containing application and assign an instance to the `delegate` property of your `CarPlayManager` instance.
 
 - note: It is very important you have a single `CarPlayManager` instance at any given time. This should be managed by your `UIApplicationDelegate` class if you choose to supply your `accessToken` to the `CarPlayManager.eventsManager` via `NavigationEventsManager.init(dataSource:accessToken:mobileEventsManager)`, instead of the Info.plist.
 */
@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject {

    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?

    /**
     Developers should assign their own object as a delegate implementing the CarPlayManagerDelegate protocol for customization.
     */
    @objc public weak var delegate: CarPlayManagerDelegate?

    /**
     If set to `true`, turn-by-turn directions will simulate the user traveling along the selected route when initiated from CarPlay.
     */
    @objc public var simulatesLocations = false

    private weak var navigationService: NavigationService?

    /**
     A multiplier to be applied to the user's speed in simulation mode.
     */
    @objc public var simulatedSpeedMultiplier = 1.0 {
        didSet {
            navigationService?.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }
    }

    public fileprivate(set) var mainMapTemplate: CPMapTemplate?
    public fileprivate(set) weak var currentNavigator: CarPlayNavigationViewController?
    public static let CarPlayWaypointKey: String = "MBCarPlayWaypoint"
    
    private var defaultMapButtons: [CPMapButton]?

    private let mapTemplateProvider = MapTemplateProvider()

    /**
     A Boolean value indicating whether the phone is connected to CarPlay.
     */
    @objc public static var isConnected = false

    /**
     The events manager used during turn-by-turn navigation while connected to
     CarPlay.
     */
    @objc public let eventsManager: NavigationEventsManager
    
    /**
     The object that calculates routes when the user interacts with the CarPlay
     interface.
     */
    @objc public let directions: Directions

    /**
     The styles displayed in the CarPlay interface.
     */
    @objc public var styles: [Style] {
        didSet {
            if let mapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
                mapViewController.styles = styles
            }
            currentNavigator?.styles = styles
        }
    }

    /**
     Initializes a new CarPlay manager that manages a connection to the CarPlay
     interface.
     
     - parameter styles: The styles to display in the CarPlay interface. If this
        argument is omitted, `DayStyle` and `NightStyle` are displayed by
        default.
     - parameter directions: The object that calculates routes when the user
        interacts with the CarPlay interface. If this argument is `nil` or
        omitted, the shared `Directions` object is used by default.
     - parameter eventsManager: The events manager to use during turn-by-turn
        navigation while connected to CarPlay. If this argument is `nil` or
        omitted, a standard `NavigationEventsManager` object is used by default.
     */
    @objc public init(styles: [Style]? = nil,
                      directions: Directions? = nil,
                      eventsManager: NavigationEventsManager? = nil) {
        self.styles = styles ?? [DayStyle(), NightStyle()]
        self.directions = directions ?? .shared
        self.eventsManager = eventsManager ?? NavigationEventsManager(dataSource: nil)
        
        super.init()
    }

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
    
    /**
     The main map view displayed inside CarPlay.
     */
    @objc public var mapView: NavigationMapView? {
        let mapViewController = carWindow?.rootViewController as? CarPlayMapViewController
        return mapViewController?.mapView
    }
}


// MARK: CPApplicationDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPApplicationDelegate {

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {

        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        if let shouldDisableIdleTimer = delegate?.carplayManagerShouldDisableIdleTimer?(self) {
            UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        let viewController = CarPlayMapViewController(styles: styles)
        window.rootViewController = viewController
        self.carWindow = window

        let mapTemplate = self.mapTemplate(for: interfaceController, viewController: viewController)
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false)

        eventsManager.sendCarPlayConnectEvent()
    }

    public func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        CarPlayManager.isConnected = false
        self.interfaceController = nil
        carWindow?.isHidden = true

        eventsManager.sendCarPlayDisconnectEvent()

        if let shouldDisableIdleTimer = delegate?.carplayManagerShouldDisableIdleTimer?(self) {
            UIApplication.shared.isIdleTimerDisabled = !shouldDisableIdleTimer
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func mapTemplate(for interfaceController: CPInterfaceController, viewController: UIViewController) -> CPMapTemplate {

        let traitCollection = viewController.traitCollection

        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        if let leadingButtons = delegate?.carPlayManager?(self, leadingNavigationBarButtonsCompatibleWith: traitCollection, for: .browsing) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }

        if let trailingButtons = delegate?.carPlayManager?(self, trailingNavigationBarButtonsCompatibleWith: traitCollection, for: .browsing) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
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
        panButton.image = UIImage(named: "carplay_pan", in: bundle, compatibleWith: traitCollection)

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
        closeButton.image = UIImage(named: "carplay_close", in: bundle, compatibleWith: traitCollection)

        return closeButton
    }

    public func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        if mapTemplate.isPanningInterfaceVisible, let mapButtons = defaultMapButtons {
            mapTemplate.mapButtons = mapButtons
            mapTemplate.dismissPanningInterface(animated: false)
        }
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
        
        // Selected a favorite? or any item with a waypoint.
        if let userInfo = item.userInfo as? [String: Any],
            let waypoint = userInfo[CarPlayManager.CarPlayWaypointKey] as? Waypoint {
            previewRoutes(to: waypoint, completionHandler: completionHandler)
            return
        }
        
        completionHandler()
    }
    
    public func previewRoutes(to destination: Waypoint, completionHandler: @escaping CompletionHandler) {
        guard let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let userLocation = rootViewController.mapView.userLocation,
            let location = userLocation.location else {
                completionHandler()
                return
        }
        
        let name = NSLocalizedString("CARPLAY_CURRENT_LOCATION", bundle: .mapboxNavigation, value: "Current Location", comment: "Name of the waypoint associated with the current location")
        let origin = Waypoint(location: location, heading: userLocation.heading, name: name)
        
        previewRoutes(between: [origin, destination], completionHandler: completionHandler)
    }
    
    public func previewRoutes(between waypoints: [Waypoint], completionHandler: @escaping CompletionHandler) {
        let options = NavigationRouteOptions(waypoints: waypoints)
        previewRoutes(for: options, completionHandler: completionHandler)
    }
    
    public func previewRoutes(for options: RouteOptions, completionHandler: @escaping CompletionHandler) {
        calculate(options) { [weak self] (waypoints, routes, error) in
            self?.didCalculate(routes,
                               for: options,
                               between: waypoints,
                               error: error,
                               completionHandler: completionHandler)
        }
    }
    
    internal func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) {
        directions.calculate(options, completionHandler: completionHandler)
    }
    
    
    internal func didCalculate(_ routes: [Route]?, for routeOptions: RouteOptions, between waypoints: [Waypoint]?, error: NSError?, completionHandler: @escaping () -> Void) {
        defer {
            completionHandler()
        }
        
        guard let interfaceController = interfaceController,
              let mapTemplate = interfaceController.rootTemplate as? CPMapTemplate else {
            return
        }
        
        if let error = error {
            let okTitle = NSLocalizedString("CARPLAY_OK", bundle: .mapboxNavigation, value: "OK", comment: "CPNavigationAlert OK button title")
            let okAction = CPAlertAction(title: okTitle, style: .default) { _ in
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
               fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
               shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
               briefDateComponentsFormatter.string(from: route.expectedTravelTime)!
            ]
            let routeChoice = CPRouteChoice(summaryVariants: summaryVariants, additionalInformationVariants: [route.description], selectionSummaryVariants: [route.description])
            routeChoice.userInfo = route
            return routeChoice
        }
        
        let originPlacemark = MKPlacemark(coordinate: waypoints.first!.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: waypoints.last!.coordinate, addressDictionary: ["street": waypoints.last!.name ?? ""])
        
        let trip = CPTrip(origin: MKMapItem(placemark: originPlacemark), destination: MKMapItem(placemark: destinationPlacemark), routeChoices: routeChoices)
        trip.userInfo = routeOptions
        
        let goTitle = NSLocalizedString("CARPLAY_GO", bundle: .mapboxNavigation, value: "Go", comment: "Title for start button in CPTripPreviewTextConfiguration")
        let alternativeRoutesTitle = NSLocalizedString("CARPLAY_MORE_ROUTES", bundle: .mapboxNavigation, value: "More Routes", comment: "Title for alternative routes in CPTripPreviewTextConfiguration")
        let overviewTitle = NSLocalizedString("CARPLAY_OVERVIEW", bundle: .mapboxNavigation, value: "Overview", comment: "Title for overview button in CPTripPreviewTextConfiguration")
        let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: goTitle, additionalRoutesButtonTitle: alternativeRoutesTitle, overviewButtonTitle: overviewTitle)
        
        let traitCollection = (self.carWindow?.rootViewController as! CarPlayMapViewController).traitCollection
        let leadingButtons = delegate?.carPlayManager?(self, leadingNavigationBarButtonsCompatibleWith: traitCollection, for: .previewing)
        let trailingButtons = delegate?.carPlayManager?(self, trailingNavigationBarButtonsCompatibleWith: traitCollection, for: .previewing)
        
        let previewMapTemplate = mapTemplateProvider.mapTemplate(forPreviewing: trip, leadingButtons: leadingButtons, trailingButtons: trailingButtons, mapDelegate: self)
        
        interfaceController.pushTemplate(previewMapTemplate, animated: true)
        
        previewMapTemplate.showTripPreviews([trip], textConfiguration: defaultPreviewText)
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
        var service: NavigationService
        
        if let override = delegate?.carPlayManager?(self, navigationServiceAlong: route) {
            service = override
        } else {
            service = MapboxNavigationService(route: route, simulating: simulatesLocations ? .always : .onPoorGPS)
        }

        if simulatesLocations == true {
            service.simulationMode = .always
            service.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }

        interfaceController.popToRootTemplate(animated: false)
        let navigationMapTemplate = self.mapTemplate(forNavigating: trip)
        interfaceController.setRootTemplate(navigationMapTemplate, animated: true)

        let navigationViewController = CarPlayNavigationViewController(navigationService: service,
                                                                       mapTemplate: navigationMapTemplate,
                                                                       interfaceController: interfaceController,
                                                                       manager: self,
                                                                       styles: styles)
        navigationViewController.startNavigationSession(for: trip)
        navigationViewController.carPlayNavigationDelegate = self
        currentNavigator = navigationViewController
        navigationService = service

        carPlayMapViewController.isOverviewingRoutes = false
        carPlayMapViewController.present(navigationViewController, animated: true, completion: nil)

        let mapView = carPlayMapViewController.mapView
        mapView.removeRoutes()
        mapView.removeWaypoints()

        delegate?.carPlayManager(self, didBeginNavigationWith: service)
    }

    func mapTemplate(forNavigating trip: CPTrip) -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let showFeedbackButton = CPMapButton { [weak self] (button) in
            self?.currentNavigator?.showFeedback()
        }
        showFeedbackButton.image = UIImage(named: "carplay_feedback", in: .mapboxNavigation, compatibleWith: nil)

        let overviewButton = CPMapButton { [weak self] (button) in
            guard let navigationViewController = self?.currentNavigator else {
                return
            }
            navigationViewController.tracksUserCourse = !navigationViewController.tracksUserCourse

            let imageName = navigationViewController.tracksUserCourse ? "carplay_overview" : "carplay_locate"
            button.image = UIImage(named: imageName, in: .mapboxNavigation, compatibleWith: nil)
        }
        overviewButton.image = UIImage(named: "carplay_overview", in: .mapboxNavigation, compatibleWith: nil)

        mapTemplate.mapButtons = [overviewButton, showFeedbackButton]

        if let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let leadingButtons = delegate?.carPlayManager?(self, leadingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, for: .navigating) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        
        let muteTitle = NSLocalizedString("CARPLAY_MUTE", bundle: .mapboxNavigation, value: "Mute", comment: "Title for mute button")
        let unmuteTitle = NSLocalizedString("CARPLAY_UNMUTE", bundle: .mapboxNavigation, value: "Unmute", comment: "Title for unmute button")
        
        let muteButton = CPBarButton(type: .text) { (button: CPBarButton) in
            NavigationSettings.shared.voiceMuted = !NavigationSettings.shared.voiceMuted
            button.title = NavigationSettings.shared.voiceMuted ? unmuteTitle : muteTitle
        }
        muteButton.title = NavigationSettings.shared.voiceMuted ? unmuteTitle : muteTitle
        mapTemplate.leadingNavigationBarButtons.insert(muteButton, at: 0)

        if let rootViewController = self.carWindow?.rootViewController as? CarPlayMapViewController,
            let trailingButtons = delegate?.carPlayManager?(self, trailingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, for: .navigating) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        let exitButton = CPBarButton(type: .text) { [weak self] (button: CPBarButton) in
            self?.currentNavigator?.exitNavigation(byCanceling: true)
        }
        exitButton.title = NSLocalizedString("CARPLAY_END", bundle: .mapboxNavigation, value: "End", comment: "Title for end navigation button")
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
        
        delegate?.carPlayManager?(self, selectedPreviewFor: trip, using: routeChoice)
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
        }
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        if mapTemplate == interfaceController?.rootTemplate, let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
            carPlayMapViewController.recenterButton.isHidden = carPlayMapViewController.mapView.userTrackingMode != .none
        }

        //We want the panning surface to have "friction". If the user did not "flick" fast/hard enough, do not update the map with a final animation.
        guard sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y)) > 100 else {
            return
        }
        
        let decelerationRate: CGFloat = 0.9
        let offset = CGPoint(x: velocity.x * decelerationRate / 4, y: velocity.y * decelerationRate / 4)
        updatePan(by: offset, mapTemplate: mapTemplate, animated: true)
    }
    
    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }
        
        let mode = carPlayMapViewController.mapView.userTrackingMode
        carPlayMapViewController.recenterButton.isHidden = mode != .none
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint) {
        let mapView: NavigationMapView
        if let navigationViewController = currentNavigator, mapTemplate == navigationViewController.mapTemplate {
            mapView = navigationViewController.mapView!
        } else if let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController {
            mapView = carPlayMapViewController.mapView
        } else {
            return
        }
        
        mapView.setContentInset(mapView.safeArea, animated: false) //make sure this is always up to date in-case safe area changes during gesture
        updatePan(by: translation, mapTemplate: mapTemplate, animated: false)

        
    }
    
    private func updatePan(by offset: CGPoint, mapTemplate: CPMapTemplate, animated: Bool) {
        let mapView: NavigationMapView
        if let navigationViewController = currentNavigator, mapTemplate == navigationViewController.mapTemplate {
            mapView = navigationViewController.mapView!
        } else if let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController {
            mapView = carPlayMapViewController.mapView
        } else {
            return
        }

        let coordinate = self.coordinate(of: offset, in: mapView)
        mapView.setCenter(coordinate, animated: animated)
    }

    func coordinate(of offset: CGPoint, in mapView: NavigationMapView) -> CLLocationCoordinate2D {
        let contentFrame = UIEdgeInsetsInsetRect(mapView.bounds, mapView.safeArea)
        let centerPoint = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x - offset.x, y: centerPoint.y - offset.y)

        return mapView.convert(endCameraPoint, toCoordinateFrom: mapView)
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        guard let carPlayMapViewController = self.carWindow?.rootViewController as? CarPlayMapViewController else {
            return
        }

        // Determine the screen distance to pan by based on the distance from the visual center to the closest side.
        let mapView = carPlayMapViewController.mapView
        let contentFrame = UIEdgeInsetsInsetRect(mapView.bounds, mapView.safeArea)
        let increment = min(mapView.bounds.width, mapView.bounds.height) / 2.0
        
        // Calculate the distance in physical units from the visual center to where it would be after panning downwards.
        let downshiftedCenter = CGPoint(x: contentFrame.midX, y: contentFrame.midY + increment)
        let downshiftedCenterCoordinate = mapView.convert(downshiftedCenter, toCoordinateFrom: mapView)
        let distance = mapView.centerCoordinate.distance(to: downshiftedCenterCoordinate)
        
        // Shift the center coordinate by that distance in the specified direction.
        guard let relativeDirection = CLLocationDirection(panDirection: direction) else {
            return
        }
        let shiftedDirection = (mapView.direction + relativeDirection).wrap(min: 0, max: 360)
        let shiftedCenterCoordinate = mapView.centerCoordinate.coordinate(at: distance, facing: shiftedDirection)
        mapView.setCenter(shiftedCenterCoordinate, animated: true)
    }

}

// MARK: CarPlayNavigationDelegate
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


@available(iOS 12.0, *)
internal class MapTemplateProvider {

    func mapTemplate(forPreviewing trip: CPTrip, leadingButtons: [CPBarButton]?, trailingButtons: [CPBarButton]?, mapDelegate: CPMapTemplateDelegate) -> CPMapTemplate {
        
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = mapDelegate
        
        if let leadingButtons = leadingButtons {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        
        if let trailingButtons = trailingButtons {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        
        return mapTemplate
    }

}

#else
/**
 CarPlay support requires iOS 12.0 or above and the CarPlay framework.
 */
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject {
    /**
     A Boolean value indicating whether the phone is connected to CarPlay.
     */
    @objc public static var isConnected = false
}
#endif
