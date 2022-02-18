import CarPlay
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

/**
 `CarPlayManager` is the main object responsible for orchestrating interactions with a Mapbox map on CarPlay.
 
 Messages declared in the `CPApplicationDelegate` protocol should be sent to this object in the containing application's application delegate. Implement `CarPlayManagerDelegate` in the containing application and assign an instance to the `delegate` property of your `CarPlayManager` instance.
 
 - note: It is very important you have a single `CarPlayManager` instance at any given time. This should be managed by your `UIApplicationDelegate` class if you choose to supply your `accessToken` to the `CarPlayManager.eventsManager` via `NavigationEventsManager` initializer, instead of the Info.plist.
 */
@available(iOS 12.0, *)
public class CarPlayManager: NSObject {
    
    // MARK: CarPlay Infrastructure
    
    /**
     A controller that manages the templates for constructing a scene’s user interface.
     */
    public fileprivate(set) var interfaceController: CPInterfaceController?
    
    /**
     Main window for content, presented on the CarPlay screen.
     */
    public fileprivate(set) var carWindow: UIWindow?

    /**
     A template that displays a navigation overlay on the map.
     */
    public fileprivate(set) var mainMapTemplate: CPMapTemplate?
    
    /**
     A Boolean value indicating whether the phone is connected to CarPlay.
     */
    public static var isConnected = false
    
    // MARK: Navigation Configuration
    
    /**
     Developers should assign their own object as a delegate implementing the CarPlayManagerDelegate protocol for customization.
     */
    public weak var delegate: CarPlayManagerDelegate?

    /**
     `UIViewController`, which provides a fully-featured turn-by-turn navigation UI for CarPlay.
     */
    public fileprivate(set) weak var carPlayNavigationViewController: CarPlayNavigationViewController?
    
    /**
     Property, which contains type of `CarPlayNavigationViewController`.
     */
    public let carPlayNavigationViewControllerType: CarPlayNavigationViewController.Type

    /**
     The events manager used during turn-by-turn navigation while connected to
     CarPlay.
     */
    public let eventsManager: NavigationEventsManager
    
    /**
     The object that calculates routes when the user interacts with the CarPlay interface.
     */
    @available(*, deprecated, message: "Use `routingProvider` instead. If car play manager was not initialized using `Directions` object - this property is unused and ignored.")
    public lazy var directions: Directions = self.routingProvider as? Directions ?? NavigationSettings.shared.directions
    
    /**
     `RoutingProvider`, used to create route.
     */
    public var routingProvider: RoutingProvider
    
    /**
     Returns current `CarPlayActivity`, which is based on currently present `CPTemplate`. In case if
     `CPTemplate` was not created by `CarPlayManager` `currentActivity` will be assigned to `nil`.
     */
    public private(set) var currentActivity: CarPlayActivity?

    private weak var navigationService: NavigationService?
    private var idleTimerCancellable: IdleTimerManager.Cancellable?
    
    /**
     Programatically begins a CarPlay turn-by-turn navigation session.
     
     - parameter currentLocation: The current location of the user. This will be used to initally draw the current location icon.
     - parameter navigationService: The service with which to navigation. CarPlayNavigationViewController will observe the progress updates from this service.
     - precondition: The NavigationViewController must be fully presented at the time of this call.
     */
    public func beginNavigationWithCarPlay(using currentLocation: CLLocationCoordinate2D,
                                           navigationService: NavigationService) {
        // Stop the background `PassiveLocationProvider` sending location and heading update `mapView` before turn-by-turn navigation session starts.
        if let locationProvider = navigationMapView?.mapView.location.locationProvider {
            locationProvider.stopUpdatingLocation()
            locationProvider.stopUpdatingHeading()
            if let passiveLocationProvider = locationProvider as? PassiveLocationProvider {
                passiveLocationProvider.locationManager.pauseTripSession()
            }
        }
        
        var trip = CPTrip(routeResponse: navigationService.indexedRouteResponse.routeResponse)
        trip = delegate?.carPlayManager(self, willPreview: trip) ?? trip
        
        self.navigationService = navigationService
        
        if let mapTemplate = mainMapTemplate, let routeChoice = trip.routeChoices.first {
            self.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
        }
    }
    
    /**
     Initializes a new CarPlay manager that manages a connection to the CarPlay interface.
     
     - parameter styles: The styles to display in the CarPlay interface. If this argument is omitted, `DayStyle` and `NightStyle` are displayed by default.
     - parameter directions: The object that calculates routes when the user interacts with the CarPlay interface. If this argument is `nil` or omitted, the shared `Directions` object is used by default.
     - parameter eventsManager: The events manager to use during turn-by-turn navigation while connected to CarPlay. If this argument is `nil` or omitted, a standard `NavigationEventsManager` object is used by default.
     */
    @available(*, deprecated, renamed: "init(styles:routingProvider:eventsManager:carPlayNavigationViewControllerClass:)")
    public convenience init(styles: [Style]? = nil,
                            directions: Directions? = nil,
                            eventsManager: NavigationEventsManager? = nil) {
        self.init(styles: styles,
                  routingProvider: directions ?? NavigationSettings.shared.directions,
                  eventsManager: eventsManager,
                  carPlayNavigationViewControllerClass: nil)
    }
    
    /**
     Initializes a new CarPlay manager that manages a connection to the CarPlay interface.
     
     - parameter styles: The styles to display in the CarPlay interface. If this argument is omitted, `DayStyle` and `NightStyle` are displayed by default.
     - parameter routingProvider: The object that calculates routes when the user interacts with the CarPlay interface.
     - parameter eventsManager: The events manager to use during turn-by-turn navigation while connected to CarPlay. If this argument is `nil` or omitted, a standard `NavigationEventsManager` object is used by default.
     */
    public convenience init(styles: [Style]? = nil,
                            routingProvider: RoutingProvider,
                            eventsManager: NavigationEventsManager? = nil) {
        self.init(styles: styles,
                  routingProvider: routingProvider,
                  eventsManager: eventsManager,
                  carPlayNavigationViewControllerClass: nil)
    }
    
    init(styles: [Style]? = nil,
         routingProvider: RoutingProvider,
         eventsManager: NavigationEventsManager? = nil,
         carPlayNavigationViewControllerClass: CarPlayNavigationViewController.Type? = nil) {
        self.styles = styles ?? [DayStyle(), NightStyle()]
        self.routingProvider = routingProvider
        self.eventsManager = eventsManager ?? .init(activeNavigationDataSource: nil,
                                                    accessToken: NavigationSettings.shared.directions.credentials.accessToken)
        self.mapTemplateProvider = MapTemplateProvider()
        self.carPlayNavigationViewControllerType = carPlayNavigationViewControllerClass ?? CarPlayNavigationViewController.self
        
        super.init()
        
        self.mapTemplateProvider.delegate = self
    }
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationCameraStateDidChange(_:)),
                                               name: .navigationCameraStateDidChange,
                                               object: carPlayMapViewController?.navigationMapView.navigationCamera)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationCameraStateDidChange,
                                                  object: carPlayMapViewController?.navigationMapView.navigationCamera)
    }
    
    @objc func navigationCameraStateDidChange(_ notification: Notification) {
        guard let state = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.state] as? NavigationCameraState else { return }
        switch state {
        case .idle:
            carPlayMapViewController?.recenterButton.isHidden = false
        case .transitionToFollowing, .following:
            carPlayMapViewController?.recenterButton.isHidden = true
        case .transitionToOverview, .overview:
            break
        }
    }
    
    // MARK: Map Configuration
    
    /**
     The styles displayed in the CarPlay interface.
     */
    public var styles: [Style] {
        didSet {
            carPlayMapViewController?.styles = styles
            carPlayNavigationViewController?.styles = styles
        }
    }
    
    /**
     The view controller for orchestrating the Mapbox map, the interface styles and the map template buttons on CarPlay.
     */
    public var carPlayMapViewController: CarPlayMapViewController? {
        if let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
            return carPlayMapViewController
        }
        return nil
    }
    
    /**
     The main `NavigationMapView` displayed inside CarPlay.
     */
    public var navigationMapView: NavigationMapView? {
        return carPlayMapViewController?.navigationMapView
    }

    var mapTemplateProvider: MapTemplateProvider
    
    // MARK: Simulating a Route
    
    /**
     If set to `true`, turn-by-turn directions will simulate the user traveling along the selected route when initiated from CarPlay.
     */
    public var simulatesLocations = false

    /**
     A multiplier to be applied to the user's speed in simulation mode.
     */
    public var simulatedSpeedMultiplier = 1.0 {
        didSet {
            navigationService?.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }
    }
    
    // MARK: Customizing the Bar Buttons

    /**
     The bar button that exits the navigation session.
     */
    public lazy var exitButton: CPBarButton = {
        let exitButton = CPBarButton(type: .text) { [weak self] (button: CPBarButton) in
            self?.carPlayNavigationViewController?.exitNavigation(byCanceling: true)
        }
        
        exitButton.title = NSLocalizedString("CARPLAY_END",
                                             bundle: .mapboxNavigation,
                                             value: "End",
                                             comment: "Title for end navigation button")
        
        return exitButton
    }()
    
    /**
     The bar button that mutes the voice turn-by-turn instruction announcements during navigation.
     */
    public lazy var muteButton: CPBarButton = {
        let muteTitle = NSLocalizedString("CARPLAY_MUTE",
                                          bundle: .mapboxNavigation,
                                          value: "Mute",
                                          comment: "Title for mute button")
        
        let unmuteTitle = NSLocalizedString("CARPLAY_UNMUTE",
                                            bundle: .mapboxNavigation,
                                            value: "Unmute",
                                            comment: "Title for unmute button")
        
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
            self?.carPlayNavigationViewController?.showFeedback()
        }
        
        showFeedbackButton.image = UIImage(named: "carplay_feedback",
                                           in: .mapboxNavigation,
                                           compatibleWith: nil)
        
        return showFeedbackButton
    }()
    
    /**
     The bar button that shows the selected route overview on the map.
     */
    public lazy var userTrackingButton: CPMapButton = {
        let userTrackingButton = CPMapButton { [weak self] button in
            guard let navigationMapView = self?.carPlayNavigationViewController?.navigationMapView else { return }
            
            if navigationMapView.navigationCamera.state == .following {
                navigationMapView.navigationCamera.moveToOverview()
            } else {
                navigationMapView.navigationCamera.follow()
            }
        }
        
        userTrackingButton.image = UIImage(named: "carplay_overview",
                                           in: .mapboxNavigation,
                                           compatibleWith: nil)
        
        return userTrackingButton
    }()
}

// MARK: CPApplicationDelegate Methods

@available(iOS 12.0, *)
extension CarPlayManager: CPApplicationDelegate {
    
    public func application(_ application: UIApplication,
                            didConnectCarInterfaceController interfaceController: CPInterfaceController,
                            to window: CPWindow) {
        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let shouldDisableIdleTimer = delegate?.carPlayManagerShouldDisableIdleTimer(self) ?? true
        if shouldDisableIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }

        let carPlayMapViewController = CarPlayMapViewController(styles: styles)
        carPlayMapViewController.delegate = self
        window.rootViewController = carPlayMapViewController
        self.carWindow = window

        let mapTemplate = previewMapTemplate()
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false)
            
        eventsManager.sendCarPlayConnectEvent()
        
        subscribeForNotifications()
    }

    public func application(_ application: UIApplication,
                            didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
                            from window: CPWindow) {
        CarPlayManager.isConnected = false
        self.interfaceController = nil
        
        window.rootViewController = nil
        window.isHidden = true
        window.removeFromSuperview()

        mainMapTemplate = nil
        carWindow = nil

        eventsManager.sendCarPlayDisconnectEvent()

        idleTimerCancellable = nil
        
        unsubscribeFromNotifications()
    }

    func previewMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self
        
        let currentActivity: CarPlayActivity = .browsing
        mapTemplate.userInfo = [
            CarPlayManager.currentActivityKey: currentActivity
        ]

        guard let carPlayMapViewController = carPlayMapViewController else { return mapTemplate }
           
        let traitCollection = carPlayMapViewController.traitCollection
        
        if let leadingButtons = delegate?.carPlayManager(self,
                                                         leadingNavigationBarButtonsCompatibleWith: traitCollection,
                                                         in: mapTemplate,
                                                         for: currentActivity) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }

        if let trailingButtons = delegate?.carPlayManager(self,
                                                          trailingNavigationBarButtonsCompatibleWith: traitCollection,
                                                          in: mapTemplate,
                                                          for: currentActivity) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }

        if let mapButtons = delegate?.carPlayManager(self,
                                                     mapButtonsCompatibleWith: traitCollection,
                                                     in: mapTemplate,
                                                     for: currentActivity) {
            mapTemplate.mapButtons = mapButtons
        } else if let mapButtons = browsingMapButtons(for: mapTemplate) {
            mapTemplate.mapButtons = mapButtons
        }
        
        return mapTemplate
    }

    public func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        if mapTemplate.isPanningInterfaceVisible,
           let carPlayMapViewController = carPlayMapViewController {
            if let mapButtons = delegate?.carPlayManager(self,
                                                         mapButtonsCompatibleWith: carPlayMapViewController.traitCollection,
                                                         in: mapTemplate,
                                                         for: .browsing) {
                mapTemplate.mapButtons = mapButtons
            } else if let mapButtons = browsingMapButtons(for: mapTemplate) {
                mapTemplate.mapButtons = mapButtons
            }
            
            mapTemplate.dismissPanningInterface(animated: false)
        }
    }
    
    private func browsingMapButtons(for mapTemplate: CPMapTemplate) -> [CPMapButton]? {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return nil
        }
        
        let panMapButton = carPlayMapViewController.panningInterfaceDisplayButton(for: mapTemplate)
        carPlayMapViewController.panMapButton = panMapButton
        
        let mapButtons = [
            carPlayMapViewController.recenterButton,
            panMapButton,
            carPlayMapViewController.zoomInButton,
            carPlayMapViewController.zoomOutButton
        ]
        
        return mapButtons
    }
}

// MARK: CPInterfaceControllerDelegate Methods

@available(iOS 12.0, *)
extension CarPlayManager: CPInterfaceControllerDelegate {
    
    public func templateWillAppear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateWillAppear: template, animated: animated)
        
        if template == interfaceController?.rootTemplate,
           let carPlayMapViewController = carPlayMapViewController {
            carPlayMapViewController.recenterButton.isHidden = true
        }
        
        if let userInfo = template.userInfo as? Dictionary<String, Any>,
           let currentActivity = userInfo[CarPlayManager.currentActivityKey] as? CarPlayActivity {
            self.currentActivity = currentActivity
        } else {
            self.currentActivity = nil
        }
    }
    
    public func templateDidAppear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateDidAppear: template, animated: animated)
        
        guard interfaceController?.topTemplate == mainMapTemplate,
              template == interfaceController?.rootTemplate,
              let carPlayMapViewController = carPlayMapViewController else { return }
        
        let navigationMapView = carPlayMapViewController.navigationMapView
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
    }
    
    public func templateWillDisappear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateWillDisappear: template, animated: animated)
        
        guard let interfaceController = interfaceController,
              let topTemplate = interfaceController.topTemplate,
              type(of: topTemplate) == CPSearchTemplate.self ||
                interfaceController.templates.count == 1 else { return }
        
        navigationMapView?.navigationCamera.follow()
    }
    
    public func templateDidDisappear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateDidDisappear: template, animated: animated)
    }
}

@available(iOS 12.0, *)
extension CarPlayManager {
    
    // MARK: Route Preview
    
    /**
     Calculates routes to the given destination using the [Mapbox Directions API](https://www.mapbox.com/api-documentation/navigation/#directions) and previews them on a map.
     
     Upon successful calculation a new template will be pushed onto the template navigation hierarchy.
     
     - parameter destination: A final destination `Waypoint`.
     - parameter completionHandler: A closure to be executed when the calculation completes.
     */
    public func previewRoutes(to destination: Waypoint, completionHandler: @escaping CompletionHandler) {
        guard let carPlayMapViewController = carPlayMapViewController,
              let userLocation = carPlayMapViewController.navigationMapView.mapView.location.latestLocation else {
            completionHandler()
            return
        }
        
        let name = NSLocalizedString("CARPLAY_CURRENT_LOCATION",
                                     bundle: .mapboxNavigation,
                                     value: "Current Location",
                                     comment: "Name of the waypoint associated with the current location")
        
        let location = CLLocation(latitude: userLocation.coordinate.latitude,
                                  longitude: userLocation.coordinate.longitude)
        
        let origin = Waypoint(location: location,
                              heading: userLocation.heading,
                              name: name)
        
        previewRoutes(between: [origin, destination], completionHandler: completionHandler)
    }
    
    /**
     Allows to preview routes for a list of `Waypoint` objects.
     
     - parameter waypoints: A list of `Waypoint` objects.
     - parameter completionHandler: A closure to be executed when the calculation completes.
     */
    public func previewRoutes(between waypoints: [Waypoint], completionHandler: @escaping CompletionHandler) {
        let options = NavigationRouteOptions(waypoints: waypoints)
        previewRoutes(for: options, completionHandler: completionHandler)
    }
    
    /**
     Calculates routes satisfying the given options using the [Mapbox Directions API](https://www.mapbox.com/api-documentation/navigation/#directions) and previews them on a map.
     
     - parameter routeOptions: A `RouteOptions` object, which specifies the criteria for results
     returned by the Mapbox Directions API.
     - parameter completionHandler: A closure to be executed when the calculation completes.
     */
    public func previewRoutes(for options: RouteOptions, completionHandler: @escaping CompletionHandler) {
        calculate(options) { [weak self] (session, result) in
            guard let self = self else {
                completionHandler()
                return
            }
            
            self.didCalculate(result,
                              in: session,
                              for: options,
                              completionHandler: completionHandler)
        }
    }
    
    func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) {
        routingProvider.calculateRoutes(options: options, completionHandler: completionHandler)
    }
    
    func didCalculate(_ result: Result<RouteResponse, DirectionsError>,
                      in session: Directions.Session,
                      for routeOptions: RouteOptions,
                      completionHandler: CompletionHandler) {
        defer {
            completionHandler()
        }
        
        switch result {
        case let .failure(error):
            guard let delegate = delegate,
                  let alert = delegate.carPlayManager(self,
                                                      didFailToFetchRouteBetween: routeOptions.waypoints,
                                                      options: routeOptions,
                                                      error: error) else {
                return
            }
            
            let mapTemplate = interfaceController?.rootTemplate as? CPMapTemplate
            popToRootTemplate(interfaceController: interfaceController, animated: true)
            mapTemplate?.present(navigationAlert: alert, animated: true)
            return
        case let .success(response):
            if let traitCollection = (self.carWindow?.rootViewController as? CarPlayMapViewController)?.traitCollection,
               let interfaceController = interfaceController {
                
                var trip = CPTrip(routeResponse: response)
                trip = delegate?.carPlayManager(self, willPreview: trip) ?? trip

                let previewMapTemplate = mapTemplateProvider.mapTemplate(forPreviewing: trip,
                                                                         traitCollection: traitCollection,
                                                                         mapDelegate: self)
                
                var previewText = defaultTripPreviewTextConfiguration()
                if let customPreviewText = delegate?.carPlayManager(self, willPreview: trip, with: previewText) {
                    previewText = customPreviewText
                }
                
                previewMapTemplate.showTripPreviews([trip], textConfiguration: previewText)
                interfaceController.pushTemplate(previewMapTemplate, animated: true)
            }
        }
    }

    private func defaultTripPreviewTextConfiguration() -> CPTripPreviewTextConfiguration {
        let goTitle = NSLocalizedString("CARPLAY_GO",
                                        bundle: .mapboxNavigation,
                                        value: "Go",
                                        comment: "Title for start button in CPTripPreviewTextConfiguration")
        
        let alternativeRoutesTitle = NSLocalizedString("CARPLAY_MORE_ROUTES",
                                                       bundle: .mapboxNavigation,
                                                       value: "More Routes",
                                                       comment: "Title for alternative routes in CPTripPreviewTextConfiguration")
        
        let overviewTitle = NSLocalizedString("CARPLAY_OVERVIEW",
                                              bundle: .mapboxNavigation,
                                              value: "Overview",
                                              comment: "Title for overview button in CPTripPreviewTextConfiguration")

        let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: goTitle,
                                                                additionalRoutesButtonTitle: alternativeRoutesTitle,
                                                                overviewButtonTitle: overviewTitle)
        return defaultPreviewText
    }
}

// MARK: CPMapTemplateDelegate Methods

@available(iOS 12.0, *)
extension CarPlayManager: CPMapTemplateDelegate {
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            startedTrip trip: CPTrip,
                            using routeChoice: CPRouteChoice) {
        guard let interfaceController = interfaceController,
              let carPlayMapViewController = carPlayMapViewController else {
                  return
              }
        
        guard let routeResponse = routeChoice.routeResponseFromUserInfo,
              let routeOptions = routeResponse.options as? RouteOptions else {
                  preconditionFailure("CPRouteChoice should contain `RouteResponseUserInfo` struct.")
              }

        mapTemplate.hideTripPreviews()
        
        let desiredSimulationMode: SimulationMode = simulatesLocations ? .always : .inTunnels
        
        let navigationService = self.navigationService ??
        delegate?.carPlayManager(self,
                                 navigationServiceFor: routeResponse.response,
                                 routeIndex: routeResponse.routeIndex,
                                 routeOptions: routeOptions,
                                 desiredSimulationMode: desiredSimulationMode) ??
        MapboxNavigationService(routeResponse: routeResponse.response,
                                routeIndex: routeResponse.routeIndex,
                                routeOptions: routeOptions,
                                routingProvider: NavigationSettings.shared.directions,
                                credentials: NavigationSettings.shared.directions.credentials,
                                simulating: desiredSimulationMode)
        
        // Store newly created `MapboxNavigationService`.
        self.navigationService = navigationService

        if simulatesLocations {
            navigationService.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }
        popToRootTemplate(interfaceController: interfaceController, animated: false)
        let navigationMapTemplate = self.navigationMapTemplate()
        interfaceController.setRootTemplate(navigationMapTemplate, animated: true)

        let carPlayNavigationViewController = carPlayNavigationViewControllerType.init(navigationService: navigationService,
                                                                                       mapTemplate: navigationMapTemplate,
                                                                                       interfaceController: interfaceController,
                                                                                       manager: self,
                                                                                       styles: styles)
        carPlayNavigationViewController.startNavigationSession(for: trip)
        carPlayNavigationViewController.delegate = self
        carPlayNavigationViewController.modalPresentationStyle = .fullScreen
        self.carPlayNavigationViewController = carPlayNavigationViewController

        carPlayMapViewController.present(carPlayNavigationViewController, animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.carPlayManager(self, didPresent: carPlayNavigationViewController)
        }
        
        let navigationMapView = carPlayMapViewController.navigationMapView
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
    }

    func navigationMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self
        
        let currentActivity: CarPlayActivity = .navigating
        mapTemplate.userInfo = [
            CarPlayManager.currentActivityKey: currentActivity
        ]

        updateNavigationButtons(for: mapTemplate)
        
        return mapTemplate
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            selectedPreviewFor trip: CPTrip,
                            using routeChoice: CPRouteChoice) {
        guard let carPlayMapViewController = carPlayMapViewController else { return }
        
        guard let routeResponse = routeChoice.routeResponseFromUserInfo,
              var routes = routeResponse.response.routes,
              routes.indices.contains(routeResponse.routeIndex) else {
                  preconditionFailure("CPRouteChoice should contain `RouteResponseUserInfo` struct.")
              }
        
        let route = routes[routeResponse.routeIndex]
        let estimates = CPTravelEstimates(distanceRemaining: Measurement(distance: route.distance).localized(),
                                          timeRemaining: route.expectedTravelTime)
        mapTemplate.updateEstimates(estimates, for: trip)
        
        if let index = routes.firstIndex(where: { $0 === route }) {
            routes.insert(routes.remove(at: index), at: 0)
        }
        
        let navigationMapView = carPlayMapViewController.navigationMapView
        navigationMapView.showcase(routes, animated: true)
        
        delegate?.carPlayManager(self, selectedPreviewFor: trip, using: routeChoice)
    }

    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return
        }
        let navigationMapView = carPlayMapViewController.navigationMapView
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
        if let passiveLocationProvider = navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider {
            passiveLocationProvider.locationManager.resumeTripSession()
        }
        delegate?.carPlayManagerDidEndNavigation(self)
        delegate?.carPlayManagerDidEndNavigation(self, byCanceling: false)
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        // We want the panning surface to have "friction". If the user did not "flick" fast/hard enough, do not update the map with a final animation.
        guard sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y)) > 100 else {
            return
        }
        
        let decelerationRate: CGFloat = 0.9
        let offset = CGPoint(x: velocity.x * decelerationRate / 4,
                             y: velocity.y * decelerationRate / 4)
        updatePan(by: offset, mapTemplate: mapTemplate, animated: true)
    }
    
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        let traitCollection: UITraitCollection
        let currentActivity: CarPlayActivity
        if let carPlayNavigationViewController = carPlayNavigationViewController {
            currentActivity = .panningInNavigationMode
            traitCollection = carPlayNavigationViewController.traitCollection
        } else if let carPlayMapViewController = self.carPlayMapViewController {
            currentActivity = .panningInBrowsingMode
            traitCollection = carPlayMapViewController.traitCollection
        } else {
            assertionFailure("Panning interface is only supported for free-drive or active-guidance navigation.")
            return
        }
        
        // Whenever panning interface is shown (either in preview mode or during active navigation),
        // user should be given an opportunity to update buttons in `CPMapTemplate`.
        if let mapButtons = delegate?.carPlayManager(self,
                                                     mapButtonsCompatibleWith: traitCollection,
                                                     in: mapTemplate,
                                                     for: currentActivity) {
            mapTemplate.mapButtons = mapButtons
        } else {
            if let carPlayMapViewController = carPlayMapViewController {
                let closeButton = carPlayMapViewController.panningInterfaceDismissalButton(for: mapTemplate)
                carPlayMapViewController.dismissPanningButton = closeButton
                mapTemplate.mapButtons = [closeButton]
            }
        }
        
        if let leadingButtons = delegate?.carPlayManager(self,
                                                         leadingNavigationBarButtonsCompatibleWith: traitCollection,
                                                         in: mapTemplate,
                                                         for: currentActivity) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        
        if let trailingButtons = delegate?.carPlayManager(self,
                                                          trailingNavigationBarButtonsCompatibleWith: traitCollection,
                                                          in: mapTemplate,
                                                          for: currentActivity) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        
        self.currentActivity = currentActivity
    }
    
    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        if let carPlayMapViewController = carPlayMapViewController {
            let shouldShowRecenterButton = carPlayMapViewController.navigationMapView.navigationCamera.state == .idle
            carPlayMapViewController.recenterButton.isHidden = !shouldShowRecenterButton
        }
    }
    
    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let userInfo = mapTemplate.userInfo as? CarPlayUserInfo,
              let currentActivity = userInfo[CarPlayManager.currentActivityKey] as? CarPlayActivity else {
                  return
              }
        
        self.currentActivity = currentActivity
        
        updateNavigationButtons(for: mapTemplate)
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            didUpdatePanGestureWithTranslation translation: CGPoint,
                            velocity: CGPoint) {
        updatePan(by: translation, mapTemplate: mapTemplate, animated: false)
    }
    
    private func updatePan(by offset: CGPoint, mapTemplate: CPMapTemplate, animated: Bool) {
        let navigationMapView: NavigationMapView
        if let carPlayNavigationViewController = carPlayNavigationViewController,
           let validNavigationMapView = carPlayNavigationViewController.navigationMapView,
           mapTemplate == carPlayNavigationViewController.mapTemplate {
            navigationMapView = validNavigationMapView
        } else if let carPlayMapViewController = carPlayMapViewController {
            navigationMapView = carPlayMapViewController.navigationMapView
        } else {
            return
        }

        let coordinate = self.coordinate(of: offset, in: navigationMapView)
        let cameraOptions = CameraOptions(center: coordinate)
        navigationMapView.mapView.camera.ease(to: cameraOptions, duration: 1.0)
    }

    func coordinate(of offset: CGPoint, in navigationMapView: NavigationMapView) -> CLLocationCoordinate2D {
        let contentFrame = navigationMapView.bounds.inset(by: navigationMapView.mapView.safeAreaInsets)
        let centerPoint = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x - offset.x, y: centerPoint.y - offset.y)

        return navigationMapView.mapView.mapboxMap.coordinate(for: endCameraPoint)
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        // In case if `CarPlayManager.carPlayNavigationViewController` is not `nil`, it means that
        // active-guidance navigation is currently in progress. Is so, panning should be applied for
        // `NavigationMapView` instance there.
        guard let navigationMapView = carPlayNavigationViewController?.navigationMapView ??
                carPlayMapViewController?.navigationMapView else { return }
        
        // After `MapView` panning `NavigationCamera` should be moved to idle state to prevent any further changes.
        navigationMapView.navigationCamera.stop()

        // Determine the screen distance to pan by based on the distance from the visual center to the closest side.
        let contentFrame = navigationMapView.bounds.inset(by: navigationMapView.mapView.safeAreaInsets)
        let increment = min(navigationMapView.bounds.width, navigationMapView.bounds.height) / 2.0
        
        // Calculate the distance in physical units from the visual center to where it would be after panning downwards.
        let downshiftedCenter = CGPoint(x: contentFrame.midX, y: contentFrame.midY + increment)
        let downshiftedCenterCoordinate = navigationMapView.mapView.mapboxMap.coordinate(for: downshiftedCenter)
        let cameraState = navigationMapView.mapView.cameraState
        let distance = cameraState.center.distance(to: downshiftedCenterCoordinate)
        
        // Shift the center coordinate by that distance in the specified direction.
        guard let relativeDirection = CLLocationDirection(panDirection: direction) else {
            return
        }
        let shiftedDirection = (Double(cameraState.bearing) + relativeDirection).wrap(min: 0, max: 360)
        let shiftedCenterCoordinate = cameraState.center.coordinate(at: distance, facing: shiftedDirection)
        let cameraOptions = CameraOptions(center: shiftedCenterCoordinate)
        navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
    }

    private func popToRootTemplate(interfaceController: CPInterfaceController?, animated: Bool) {
        guard let interfaceController = interfaceController else { return }
        if interfaceController.templates.count > 1 {
            // TODO: CPInterfaceController.popToRootTemplate(animated:completion:) (available on iOS 14/Xcode 12)
            // should be used after Xcode 11 support is dropped.
            interfaceController.popToRootTemplate(animated: animated)
        }
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle {
        if let visualInstruction = maneuver.userInfo as? VisualInstruction, visualInstruction.containsLaneIndications {
            return .symbolOnly
        }
        return []
    }
    
    /**
     Updates buttons (map buttons, leading and trailing navigation bar buttons) for provided
     `CPMapTemplate`.
     In case if delegate methods for certain `CarPlayActivity` return nil value, default buttons
     will be used:
     - Default map buttons include user tracking button (allows to switch between overview and
     following camera modes) and show feedback button.
     - Default leading navigation bar buttons include only mute/unmute button.
     - Default trailing navigation bar buttons include only exit active navigation button.
     
     - parameter mapTemplate: `CPMapTemplate` instance, for which buttons update will be performed.
     */
    private func updateNavigationButtons(for mapTemplate: CPMapTemplate) {
        guard let userInfo = mapTemplate.userInfo as? CarPlayUserInfo,
              let currentActivity = userInfo[CarPlayManager.currentActivityKey] as? CarPlayActivity else {
                  return
              }

        let traitCollection: UITraitCollection
        if let carPlayNavigationViewController = carPlayNavigationViewController {
            traitCollection = carPlayNavigationViewController.traitCollection
        } else if let carPlayMapViewController = carPlayMapViewController {
            traitCollection = carPlayMapViewController.traitCollection
        } else {
            assertionFailure("Panning interface is only supported for free-drive or active-guidance navigation.")
            return
        }
        
        if let mapButtons = delegate?.carPlayManager(self,
                                                     mapButtonsCompatibleWith: traitCollection,
                                                     in: mapTemplate,
                                                     for: currentActivity) {
            mapTemplate.mapButtons = mapButtons
        } else {
            mapTemplate.mapButtons = [userTrackingButton, showFeedbackButton]
        }
        
        if let leadingButtons = delegate?.carPlayManager(self,
                                                         leadingNavigationBarButtonsCompatibleWith: traitCollection,
                                                         in: mapTemplate,
                                                         for: currentActivity) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        } else {
            mapTemplate.leadingNavigationBarButtons = [muteButton]
        }
        
        if let trailingButtons = delegate?.carPlayManager(self,
                                                          trailingNavigationBarButtonsCompatibleWith: traitCollection,
                                                          in: mapTemplate,
                                                          for: currentActivity) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        } else {
            mapTemplate.trailingNavigationBarButtons = [exitButton]
        }
    }
}

// MARK: CarPlayNavigationViewControllerDelegate Methods

@available(iOS 12.0, *)
extension CarPlayManager: CarPlayNavigationViewControllerDelegate {
    
    public func carPlayNavigationViewControllerWillDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                           byCanceling canceled: Bool) {
        delegate?.carPlayManagerWillEndNavigation(self, byCanceling: canceled)
    }
    
    public func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                          byCanceling canceled: Bool) {
        guard let interfaceController = interfaceController else {
            return
        }
        
        // Dismiss the template for previous arrival UI when exit the navigation.
        interfaceController.dismissTemplate(animated: true)
        // Unset existing main map template (fixes an issue with the buttons)
        mainMapTemplate = nil
        
        // Then (re-)create and assign new map template
        let mapTemplate = previewMapTemplate()
        mainMapTemplate = mapTemplate

        interfaceController.setRootTemplate(mapTemplate, animated: true)
        popToRootTemplate(interfaceController: interfaceController, animated: true)

        if let passiveLocationProvider = navigationMapView?.mapView.location.locationProvider as? PassiveLocationProvider {
            passiveLocationProvider.locationManager.resumeTripSession()
        }
        
        self.carPlayNavigationViewController = nil
        delegate?.carPlayManagerDidEndNavigation(self)
        delegate?.carPlayManagerDidEndNavigation(self, byCanceling: canceled)
    }
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return delegate?.carPlayManager(self, shouldPresentArrivalUIFor: waypoint) ?? true
    }
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                didAdd finalDestinationAnnotation: PointAnnotation,
                                                pointAnnotationManager: PointAnnotationManager) {
        delegate?.carPlayManager(self,
                                 didAdd: finalDestinationAnnotation,
                                 to: carPlayNavigationViewController,
                                 pointAnnotationManager: pointAnnotationManager)
    }
}

// MARK: CarPlayMapViewControllerDelegate Methods

@available(iOS 12.0, *)
extension CarPlayManager: CarPlayMapViewControllerDelegate {
    
    public func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                         didAdd finalDestinationAnnotation: PointAnnotation,
                                         pointAnnotationManager: PointAnnotationManager) {
        delegate?.carPlayManager(self,
                                 didAdd: finalDestinationAnnotation,
                                 to: carPlayMapViewController,
                                 pointAnnotationManager: pointAnnotationManager)
    }
}

// MARK: MapTemplateProviderDelegate Methods

@available(iOS 12.0, *)
extension CarPlayManager: MapTemplateProviderDelegate {
    
    func mapTemplateProvider(_ provider: MapTemplateProvider,
                             mapTemplate: CPMapTemplate,
                             leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                             for activity: CarPlayActivity) -> [CPBarButton]? {
        return delegate?.carPlayManager(self,
                                        leadingNavigationBarButtonsCompatibleWith: traitCollection,
                                        in: mapTemplate,
                                        for: activity)
    }
    
    func mapTemplateProvider(_ provider: MapTemplateProvider,
                             mapTemplate: CPMapTemplate,
                             trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                             for activity: CarPlayActivity) -> [CPBarButton]? {
        return delegate?.carPlayManager(self,
                                        trailingNavigationBarButtonsCompatibleWith: traitCollection,
                                        in: mapTemplate,
                                        for: activity)
    }
}

// MARK: CPTemplateApplicationSceneDelegate Methods

@available(iOS 13.0, *)
extension CarPlayManager {
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                         didConnectCarInterfaceController interfaceController: CPInterfaceController,
                                         to window: CPWindow) {
        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let shouldDisableIdleTimer = delegate?.carPlayManagerShouldDisableIdleTimer(self) ?? true
        if shouldDisableIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }

        let carPlayMapViewController = CarPlayMapViewController(styles: styles)
        carPlayMapViewController.delegate = self
        window.rootViewController = carPlayMapViewController
        carWindow = window

        let mapTemplate = previewMapTemplate()
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false)

        eventsManager.sendCarPlayConnectEvent()
        
        subscribeForNotifications()
    }

    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                         didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
                                         from window: CPWindow) {
        CarPlayManager.isConnected = false
        self.interfaceController = nil

        window.rootViewController = nil
        window.isHidden = true
        window.removeFromSuperview()

        mainMapTemplate = nil
        carWindow = nil

        eventsManager.sendCarPlayDisconnectEvent()

        idleTimerCancellable = nil
        
        unsubscribeFromNotifications()
    }
}

// MARK: CarPlayManager Constants

@available(iOS 12.0, *)
extension CarPlayManager {
    
    static let currentActivityKey = "com.mapbox.navigation.currentActivity"
}
