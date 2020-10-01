#if canImport(CarPlay)
import CarPlay
import MapboxCoreNavigation
import MapboxDirections

/**
 The activity during which a `CPTemplate` is displayed. This enumeration is used to distinguish between different templates during different phases of user interaction.
 */
@available(iOS 12.0, *)
public enum CarPlayActivity: Int {
    /// The user is browsing the map or searching for a destination.
    case browsing
    /// The user is panning while browsing the map interface.
    case panningInBrowsingMode
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
public class CarPlayManager: NSObject {
    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?

    /**
     Developers should assign their own object as a delegate implementing the CarPlayManagerDelegate protocol for customization.
     */
    public weak var delegate: CarPlayManagerDelegate?

    /**
     If set to `true`, turn-by-turn directions will simulate the user traveling along the selected route when initiated from CarPlay.
     */
    public var simulatesLocations = false

    private weak var navigationService: NavigationService?

    /**
     A multiplier to be applied to the user's speed in simulation mode.
     */
    public var simulatedSpeedMultiplier = 1.0 {
        didSet {
            navigationService?.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }
    }

    var trackingStateObservation: NSKeyValueObservation?
    
    deinit {
        trackingStateObservation = nil
    }
    
    public fileprivate(set) var mainMapTemplate: CPMapTemplate?
    public fileprivate(set) weak var currentNavigator: CarPlayNavigationViewController? {
        didSet {
            if let controller = currentNavigator {
                trackingStateObservation = controller.observe(\.tracksUserCourse) { [weak self] (controller, change) in
                    let imageName = controller.tracksUserCourse ? "carplay_overview" : "carplay_locate"
                    self?.userTrackingButton.image = UIImage(named: imageName, in: .mapboxNavigation, compatibleWith: nil)
                }
            }
        }
    }

    internal var mapTemplateProvider: MapTemplateProvider

    /**
     A Boolean value indicating whether the phone is connected to CarPlay.
     */
    public static var isConnected = false

    /**
     The events manager used during turn-by-turn navigation while connected to
     CarPlay.
     */
    public let eventsManager: NavigationEventsManager
    
    /**
     The object that calculates routes when the user interacts with the CarPlay
     interface.
     */
    public let directions: Directions
    
    public let navigationViewControllerType: CarPlayNavigationViewController.Type

    /**
     The styles displayed in the CarPlay interface.
     */
    public var styles: [Style] {
        didSet {
            if let mapViewController = carPlayMapViewController {
                mapViewController.styles = styles
            }
            currentNavigator?.styles = styles
        }
    }
    
    /**
     The view controller for orchestrating the Mapbox map, the interface styles and the map template buttons on CarPlay.
     */
    public var carPlayMapViewController: CarPlayMapViewController? {
        if let mapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
            return mapViewController
        }
        return nil
    }

    /**
     The bar button that exits the navigation session.
     */
    public lazy var exitButton: CPBarButton = {
        let exitButton = CPBarButton(type: .text) { [weak self] (button: CPBarButton) in
            self?.currentNavigator?.exitNavigation(byCanceling: true)
        }
        exitButton.title = NSLocalizedString("CARPLAY_END", bundle: .mapboxNavigation, value: "End", comment: "Title for end navigation button")
        return exitButton
    }()
    
    /**
     The bar button that mutes the voice turn-by-turn instruction announcements during navigation.
     */
    public lazy var muteButton: CPBarButton = {
        let muteTitle = NSLocalizedString("CARPLAY_MUTE", bundle: .mapboxNavigation, value: "Mute", comment: "Title for mute button")
        let unmuteTitle = NSLocalizedString("CARPLAY_UNMUTE", bundle: .mapboxNavigation, value: "Unmute", comment: "Title for unmute button")
        
        let muteButton = CPBarButton(type: .text) { (button: CPBarButton) in
            NavigationSettings.shared.voiceMuted = !NavigationSettings.shared.voiceMuted
            button.title = NavigationSettings.shared.voiceMuted ? unmuteTitle : muteTitle
        }
        muteButton.title = NavigationSettings.shared.voiceMuted ? unmuteTitle : muteTitle
        return muteButton
    }()
    
    /**
     The bar button that prompts the presented navigation view controller to display the feedback screen.
     */
    public lazy var showFeedbackButton: CPMapButton = {
        let showFeedbackButton = CPMapButton { [weak self] button in
            self?.currentNavigator?.showFeedback()
        }
        showFeedbackButton.image = UIImage(named: "carplay_feedback", in: .mapboxNavigation, compatibleWith: nil)
        
        return showFeedbackButton
    }()
    
    /**
     The bar button that shows the selected route overview on the map.
     */
    public lazy var userTrackingButton: CPMapButton = {
        let userTrackingButton = CPMapButton { [weak self] button in
            guard let navigationViewController = self?.currentNavigator else {
                return
            }
            navigationViewController.tracksUserCourse = !navigationViewController.tracksUserCourse
        }
        
        userTrackingButton.image = UIImage(named: "carplay_overview", in: .mapboxNavigation, compatibleWith: nil)
        
        return userTrackingButton
    }()
    
    @available(*, deprecated, renamed: "trackingStateButton")
    public var overviewButton: CPMapButton {
        get { return userTrackingButton }
    }
    
    /**
     The main map view displayed inside CarPlay.
     */
    public var mapView: NavigationMapView? {
        let mapViewController = carPlayMapViewController
        return mapViewController?.mapView
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
    public convenience init(styles: [Style]? = nil,
                            directions: Directions? = nil,
                            eventsManager: NavigationEventsManager? = nil) {
        self.init(styles: styles,
                  directions: directions,
                  eventsManager: eventsManager,
                  navigationViewControllerClass: nil)
    }
    
    internal init(styles: [Style]? = nil,
                  directions: Directions? = nil,
                  eventsManager: NavigationEventsManager? = nil,
                  navigationViewControllerClass: CarPlayNavigationViewController.Type? = nil) {
        self.styles = styles ?? [DayStyle(), NightStyle()]
        let mapboxDirections = directions ?? .shared
        self.directions = mapboxDirections
        self.eventsManager = eventsManager ?? NavigationEventsManager(dataSource: nil, accessToken: mapboxDirections.credentials.accessToken)
        self.mapTemplateProvider = MapTemplateProvider()
        self.navigationViewControllerType = navigationViewControllerClass ?? CarPlayNavigationViewController.self
        
        super.init()
        
        self.mapTemplateProvider.delegate = self
    }
    
    /**
     Programatically begins a carplay turn-by-turn navigation session.
     
     - parameter currentLocation: The current location of the user. This will be used to initally draw the current location icon.
     - parameter navigationService: The service with which to navigation. CarPlayNavigationViewController will observe the progress updates from this service.
     - precondition: The NavigationViewController must be fully presented at the time of this call.
     */
    public func beginNavigationWithCarPlay(using currentLocation: CLLocationCoordinate2D, navigationService: NavigationService) {
        let route = navigationService.route
        let routeOptions = navigationService.routeProgress.routeOptions
        
        var trip = CPTrip(routes: [route], routeOptions: routeOptions, waypoints: routeOptions.waypoints)
        trip = delegate?.carPlayManager(self, willPreview: trip) ?? trip
        
        self.navigationService = navigationService
        
        if let mapTemplate = mainMapTemplate, let routeChoice = trip.routeChoices.first {
            self.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
        }
    }
}

// MARK: CPApplicationDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPApplicationDelegate {
    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        if let shouldDisableIdleTimer = delegate?.carplayManagerShouldDisableIdleTimer(self) {
            UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        let carPlayMapViewController = CarPlayMapViewController(styles: styles)
        window.rootViewController = carPlayMapViewController
        self.carWindow = window

        let mapTemplate = self.mapTemplate(for: interfaceController)
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false)
            
        eventsManager.sendCarPlayConnectEvent()
    }

    public func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        CarPlayManager.isConnected = false
        self.interfaceController = nil        
        
        window.rootViewController = nil
        window.isHidden = true
        window.removeFromSuperview()

        mainMapTemplate = nil
        carWindow = nil

        eventsManager.sendCarPlayDisconnectEvent()

        if let shouldDisableIdleTimer = delegate?.carplayManagerShouldDisableIdleTimer(self) {
            UIApplication.shared.isIdleTimerDisabled = !shouldDisableIdleTimer
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func mapTemplate(for interfaceController: CPInterfaceController) -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        reloadButtons(for: mapTemplate)
        
        return mapTemplate
    }
    
    func reloadButtons(for mapTemplate: CPMapTemplate) {
        guard let mapViewController = carPlayMapViewController else {
            return
        }
           
        let traitCollection = mapViewController.traitCollection
        
        if let leadingButtons = delegate?.carPlayManager(self, leadingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate, for: .browsing) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }

        if let trailingButtons = delegate?.carPlayManager(self, trailingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate, for: .browsing) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }

        if let mapButtons = delegate?.carPlayManager(self, mapButtonsCompatibleWith: traitCollection, in: mapTemplate, for: .browsing) {
            mapTemplate.mapButtons = mapButtons
        } else if let mapButtons = self.browsingMapButtons(for: mapTemplate) {
            mapTemplate.mapButtons = mapButtons
        }
    }

    public func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        if mapTemplate.isPanningInterfaceVisible, let mapViewController = carPlayMapViewController {
            if let mapButtons = delegate?.carPlayManager(self, mapButtonsCompatibleWith: mapViewController.traitCollection, in: mapTemplate, for: .browsing) {
                mapTemplate.mapButtons = mapButtons
            } else if let mapButtons = self.browsingMapButtons(for: mapTemplate) {
                mapTemplate.mapButtons = mapButtons
            }
            
            mapTemplate.dismissPanningInterface(animated: false)
        }
    }
    
    private func browsingMapButtons(for mapTemplate: CPMapTemplate) -> [CPMapButton]? {
        guard let mapViewController = carPlayMapViewController else {
            return nil
        }
        var mapButtons = [mapViewController.recenterButton,
                          mapViewController.zoomInButton,
                          mapViewController.zoomOutButton]
        let panMapButton = mapViewController.panMapButton ?? mapViewController.panningInterfaceDisplayButton(for: mapTemplate)
        mapViewController.panMapButton = panMapButton
        mapButtons.insert(panMapButton, at: 1)
        
        return mapButtons
    }
}

// MARK: CPInterfaceControllerDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPInterfaceControllerDelegate {
    public func templateWillAppear(_ template: CPTemplate, animated: Bool) {
        if template == interfaceController?.rootTemplate, let mapViewController = carPlayMapViewController {
            mapViewController.recenterButton.isHidden = true
        }
    }
    
    public func templateDidAppear(_ template: CPTemplate, animated: Bool) {
        guard interfaceController?.topTemplate == mainMapTemplate else { return }
        if template == interfaceController?.rootTemplate, let mapViewController = carPlayMapViewController {
            let mapView = mapViewController.mapView
            mapView.removeRoutes()
            mapView.removeWaypoints()
            mapView.setUserTrackingMode(.followWithCourse, animated: true, completionHandler: nil)
        }
    }
    public func templateWillDisappear(_ template: CPTemplate, animated: Bool) {
        guard let interface = interfaceController else { return }
        
        let onFreedriveMapOrNavigating = interface.templates.count == 1

        guard let top = interface.topTemplate,
            type(of: top) == CPSearchTemplate.self || onFreedriveMapOrNavigating else { return }
        
        if onFreedriveMapOrNavigating {
            carPlayMapViewController?.isOverviewingRoutes = false
        }
        
        carPlayMapViewController?.resetCamera(animated: false)
    }
}

@available(iOS 12.0, *)
extension CarPlayManager {
    public func previewRoutes(to destination: Waypoint, completionHandler: @escaping CompletionHandler) {
        guard let rootViewController = carPlayMapViewController,
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
        calculate(options) { [weak self] (session, result) in
            
            self?.didCalculate(result,
                               in: session,
                               for: options,
                               completionHandler: completionHandler)
        }
    }
    
    internal func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) {
        directions.calculate(options, completionHandler: completionHandler)
    }
    
    internal func didCalculate(_ result: Result<RouteResponse, DirectionsError>,in session: Directions.Session, for routeOptions: RouteOptions, completionHandler: CompletionHandler) {
        defer {
            completionHandler()
        }
        
        switch result {
        case let .failure(error):
            guard let delegate = delegate,
                let alert = delegate.carPlayManager(self, didFailToFetchRouteBetween: routeOptions.waypoints, options: routeOptions, error: error) else {
                return
            }

            let mapTemplate = interfaceController?.rootTemplate as? CPMapTemplate
            popToRootTemplate(interfaceController: interfaceController, animated: true)
            mapTemplate?.present(navigationAlert: alert, animated: true)
            return
        case let .success(response):
            guard let routes = response.routes, case let .route(responseOptions) = response.options else { return }
            let waypoints = responseOptions.waypoints
            var trip = CPTrip(routes: routes, routeOptions: routeOptions, waypoints: waypoints)
            trip = delegate?.carPlayManager(self, willPreview: trip) ?? trip

            var previewText = defaultTripPreviewTextConfiguration()

            if let customPreviewText = delegate?.carPlayManager(self, willPreview: trip, with: previewText) {
                previewText = customPreviewText
            }

            let traitCollection = (self.carWindow?.rootViewController as! CarPlayMapViewController).traitCollection
            let previewMapTemplate = mapTemplateProvider.mapTemplate(forPreviewing: trip, traitCollection: traitCollection, mapDelegate: self)

            previewMapTemplate.showTripPreviews([trip], textConfiguration: previewText)
            
            guard let interfaceController = interfaceController else {
                    return
            }
            interfaceController.pushTemplate(previewMapTemplate, animated: true)
        }
    }

    private func defaultTripPreviewTextConfiguration() -> CPTripPreviewTextConfiguration {
        let goTitle = NSLocalizedString("CARPLAY_GO", bundle: .mapboxNavigation, value: "Go", comment: "Title for start button in CPTripPreviewTextConfiguration")
        let alternativeRoutesTitle = NSLocalizedString("CARPLAY_MORE_ROUTES", bundle: .mapboxNavigation, value: "More Routes", comment: "Title for alternative routes in CPTripPreviewTextConfiguration")
        let overviewTitle = NSLocalizedString("CARPLAY_OVERVIEW", bundle: .mapboxNavigation, value: "Overview", comment: "Title for overview button in CPTripPreviewTextConfiguration")

        let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: goTitle, additionalRoutesButtonTitle: alternativeRoutesTitle, overviewButtonTitle: overviewTitle)
        return defaultPreviewText
    }
}

// MARK: CPMapTemplateDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CPMapTemplateDelegate {
    public func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let interfaceController = interfaceController,
            let carPlayMapViewController = carPlayMapViewController else {
            return
        }

        mapTemplate.hideTripPreviews()

        let (route, routeIndex, options) = routeChoice.userInfo as! (Route, Int, RouteOptions)
        
        let desiredSimulationMode: SimulationMode = simulatesLocations ? .always : .onPoorGPS
        
        let service = navigationService ??
            delegate?.carPlayManager(self, navigationServiceAlong: route, routeIndex: routeIndex, routeOptions: options, desiredSimulationMode: desiredSimulationMode) ??
            MapboxNavigationService(route: route, routeIndex: routeIndex, routeOptions: options, simulating: desiredSimulationMode)
        
        navigationService = service //store the service it was newly created/fetched

        if simulatesLocations == true {
            service.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }
        popToRootTemplate(interfaceController: interfaceController, animated: false)
        let navigationMapTemplate = self.mapTemplate(forNavigating: trip)
        interfaceController.setRootTemplate(navigationMapTemplate, animated: true)

        let navigationViewController = navigationViewControllerType.init(navigationService: service,
                                                                       mapTemplate: navigationMapTemplate,
                                                                       interfaceController: interfaceController,
                                                                       manager: self,
                                                                       styles: styles)
        navigationViewController.startNavigationSession(for: trip)
        navigationViewController.carPlayNavigationDelegate = self
        currentNavigator = navigationViewController

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

        if let carPlayMapViewController = carPlayMapViewController,
            let mapButtons = delegate?.carPlayManager(self, mapButtonsCompatibleWith: carPlayMapViewController.traitCollection, in: mapTemplate, for: .navigating) {
            mapTemplate.mapButtons = mapButtons
        } else {
            mapTemplate.mapButtons = [userTrackingButton, showFeedbackButton]
        }

        if let rootViewController = carPlayMapViewController,
            let leadingButtons = delegate?.carPlayManager(self, leadingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, in: mapTemplate, for: .navigating) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        } else {
            mapTemplate.leadingNavigationBarButtons.insert(muteButton, at: 0)
        }
        
        if let rootViewController = carPlayMapViewController,
            let trailingButtons = delegate?.carPlayManager(self, trailingNavigationBarButtonsCompatibleWith: rootViewController.traitCollection, in: mapTemplate, for: .navigating) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        } else {
            mapTemplate.trailingNavigationBarButtons.append(exitButton)
        }

        return mapTemplate
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return
        }
        carPlayMapViewController.isOverviewingRoutes = true
        let mapView = carPlayMapViewController.mapView
        let (route, _, _) = routeChoice.userInfo as! (Route, Int, RouteOptions)
        
        let estimates = CPTravelEstimates(distanceRemaining: Measurement(distance: route.distance).localized(),
                                          timeRemaining: route.expectedTravelTime)
        mapTemplate.updateEstimates(estimates, for: trip)

        //FIXME: Unable to tilt map during route selection -- https://github.com/mapbox/mapbox-gl-native/issues/2259
        let topDownCamera = mapView.camera
        topDownCamera.pitch = 0
        mapView.setCamera(topDownCamera, animated: false)

        mapView.showcase([route])
        
        delegate?.carPlayManager(self, selectedPreviewFor: trip, using: routeChoice)
    }

    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = carPlayMapViewController else {
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
        if mapTemplate == interfaceController?.rootTemplate, let carPlayMapViewController = carPlayMapViewController {
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
    
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return
        }
        
        if let mapButtons = delegate?.carPlayManager(self, mapButtonsCompatibleWith: carPlayMapViewController.traitCollection, in: mapTemplate, for: .panningInBrowsingMode) {
            mapTemplate.mapButtons = mapButtons
        } else {
            let closeButton = carPlayMapViewController.dismissPanningButton ?? carPlayMapViewController.panningInterfaceDismissalButton(for: mapTemplate)
            carPlayMapViewController.dismissPanningButton = closeButton
            mapTemplate.mapButtons = [closeButton]
        }
    }
    
    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return
        }
        
        let mode = carPlayMapViewController.mapView.userTrackingMode
        carPlayMapViewController.recenterButton.isHidden = mode != .none
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint) {
        updatePan(by: translation, mapTemplate: mapTemplate, animated: false)
    }
    
    private func updatePan(by offset: CGPoint, mapTemplate: CPMapTemplate, animated: Bool) {
        let mapView: NavigationMapView
        if let navigationViewController = currentNavigator, mapTemplate == navigationViewController.mapTemplate {
            mapView = navigationViewController.mapView!
        } else if let carPlayMapViewController = carPlayMapViewController {
            mapView = carPlayMapViewController.mapView
        } else {
            return
        }

        let coordinate = self.coordinate(of: offset, in: mapView)
        mapView.setCenter(coordinate, animated: animated)
    }

    func coordinate(of offset: CGPoint, in mapView: NavigationMapView) -> CLLocationCoordinate2D {
        let contentFrame = mapView.bounds.inset(by: mapView.contentInset)
        let centerPoint = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x - offset.x, y: centerPoint.y - offset.y)

        return mapView.convert(endCameraPoint, toCoordinateFrom: mapView)
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return
        }

        // Determine the screen distance to pan by based on the distance from the visual center to the closest side.
        let mapView = carPlayMapViewController.mapView
        let contentFrame = mapView.bounds.inset(by: mapView.contentInset)
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

    private func popToRootTemplate(interfaceController: CPInterfaceController?, animated: Bool) {
        guard let interfaceController = interfaceController else { return }
        if interfaceController.templates.count > 1 {
            // TODO: CPInterfaceController.popToRootTemplate(animated:completion:) (available on iOS 14/Xcode 12) should be used after Xcode 11 support is dropped.
            interfaceController.popToRootTemplate(animated: animated)
        }
    }
}

// MARK: CarPlayNavigationDelegate
@available(iOS 12.0, *)
extension CarPlayManager: CarPlayNavigationDelegate {
    public func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool) {
        guard let interfaceController = interfaceController else {
            return
        }
        
        // Unset existing main map template (fixes an issue with the buttons)
        mainMapTemplate = nil
        
        // Then (re-)create and assign new map template
        let mapTemplate = self.mapTemplate(for: interfaceController)
        mainMapTemplate = mapTemplate

        interfaceController.setRootTemplate(mapTemplate, animated: true)
        popToRootTemplate(interfaceController: interfaceController, animated: true)
        
        delegate?.carPlayManagerDidEndNavigation(self)
    }
}

@available(iOS 12.0, *)
extension CarPlayManager: MapTemplateProviderDelegate {
    func mapTemplateProvider(_ provider: MapTemplateProvider, mapTemplate: CPMapTemplate, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, for activity: CarPlayActivity) -> [CPBarButton]? {
        return delegate?.carPlayManager(self, leadingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate, for: activity)
    }
    
    func mapTemplateProvider(_ provider: MapTemplateProvider, mapTemplate: CPMapTemplate, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, for activity: CarPlayActivity) -> [CPBarButton]? {
        return delegate?.carPlayManager(self, trailingNavigationBarButtonsCompatibleWith: traitCollection, in: mapTemplate, for: activity)
    }
}

@available(iOS 12.0, *)
internal protocol MapTemplateProviderDelegate: class {
    func mapTemplateProvider(_ provider: MapTemplateProvider, mapTemplate: CPMapTemplate, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, for activity: CarPlayActivity) -> [CPBarButton]?
    
    func mapTemplateProvider(_ provider: MapTemplateProvider, mapTemplate: CPMapTemplate, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, for activity: CarPlayActivity) -> [CPBarButton]?
}

@available(iOS 12.0, *)
internal class MapTemplateProvider: NSObject {
    weak var delegate: MapTemplateProviderDelegate?

    func mapTemplate(forPreviewing trip: CPTrip, traitCollection: UITraitCollection, mapDelegate: CPMapTemplateDelegate) -> CPMapTemplate {
        let mapTemplate = createMapTemplate()
        mapTemplate.mapDelegate = mapDelegate
        
        if let leadingButtons = delegate?.mapTemplateProvider(self, mapTemplate: mapTemplate, leadingNavigationBarButtonsCompatibleWith: traitCollection, for: .previewing) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        
        if let trailingButtons = delegate?.mapTemplateProvider(self, mapTemplate: mapTemplate, trailingNavigationBarButtonsCompatibleWith: traitCollection, for: .previewing) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        
        return mapTemplate
    }

    open func createMapTemplate() -> CPMapTemplate {
        return CPMapTemplate()
    }
}

#else
/**
 CarPlay support requires iOS 12.0 or above and the CarPlay framework.
 */
public class CarPlayManager: NSObject {
    /**
     A Boolean value indicating whether the phone is connected to CarPlay.
     */
    public static var isConnected = false
}
#endif
