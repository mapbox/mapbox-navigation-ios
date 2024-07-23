import CarPlay
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

/**
 `CarPlayManager` is the main object responsible for orchestrating interactions with a Mapbox map on CarPlay.
 
 Messages declared in the `CPApplicationDelegate` protocol should be sent to this object in the containing application's application delegate. Implement `CarPlayManagerDelegate` in the containing application and assign an instance to the `delegate` property of your `CarPlayManager` instance.
 
 - note: It is very important you have a single `CarPlayManager` instance at any given time. This should be managed by your `UIApplicationDelegate` class if you choose to supply your `accessToken` to the `CarPlayManager.eventsManager` via `NavigationEventsManager` initializer, instead of the Info.plist.
 
 - important: `CarPlayManager` view will start a Free Drive session by default when CarPlay interface is connected. You can change default behavior using `CarPlayManager.startFreeDriveAutomatically` property. For more information, see the “[Pricing](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/)” guide.
 */
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

    /// Controls whether `CarPlayManager` starts a Free Drive session automatically on map load.
    ///
    /// If you set this property to false, you can start a Free Drive session using
    /// `CarPlayMapViewController.startFreeDriveNavigation()` method. For example:
    /// ```
    /// carPlayManager.carPlayMapViewController?.startFreeDriveNavigation()
    /// ```
    public var startFreeDriveAutomatically: Bool = true
    
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
     `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    @available(*, deprecated, message: "Use `customRoutingProvider` instead. This property will be equal to `customRoutingProvider` if that is provided or a `MapboxRoutingProvider` instance otherwise.")
    public lazy var routingProvider: RoutingProvider = resolvedRoutingProvider
    
    /**
     Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     
     If set to `nil` - default Mapbox implementation will be used.
     */
    public var customRoutingProvider: RoutingProvider? = nil
    
    private lazy var defaultRoutingProvider: RoutingProvider = MapboxRoutingProvider(NavigationSettings.shared.routingProviderSource)

    var resolvedRoutingProvider: RoutingProvider {
        customRoutingProvider ?? defaultRoutingProvider
    }
    
    /**
     Returns current `CarPlayActivity`, which is based on currently present `CPTemplate`. In case if
     `CPTemplate` was not created by `CarPlayManager` `currentActivity` will be assigned to `nil`.
     */
    public private(set) var currentActivity: CarPlayActivity?

    private weak var navigationService: NavigationService?
    private var idleTimerCancellable: IdleTimerManager.Cancellable?
    private var indexedRouteResponse: IndexedRouteResponse?

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
                carPlayMapViewController?.unsubscribeFromFreeDriveNotifications()
            }
        }
        
        var trip = CPTrip(indexedRouteResponse: navigationService.indexedRouteResponse)
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
    @available(*, deprecated, renamed: "init(styles:customRoutingProvider:eventsManager:carPlayNavigationViewControllerClass:)")
    public convenience init(styles: [Style]? = nil,
                            directions: Directions? = nil,
                            eventsManager: NavigationEventsManager? = nil) {
        self.init(styles: styles,
                  customRoutingProvider: directions ?? NavigationSettings.shared.directions,
                  eventsManager: eventsManager,
                  carPlayNavigationViewControllerClass: nil)
    }
    
    /**
     Initializes a new CarPlay manager that manages a connection to the CarPlay interface.
     
     - parameter styles: The styles to display in the CarPlay interface. If this argument is omitted, `DayStyle` and `NightStyle` are displayed by default.
     - parameter routingProvider: The object that calculates routes when the user interacts with the CarPlay interface.
     - parameter eventsManager: The events manager to use during turn-by-turn navigation while connected to CarPlay. If this argument is `nil` or omitted, a standard `NavigationEventsManager` object is used by default.
     */
    @available(*, deprecated, renamed: "init(styles:customRoutingProvider:eventsManager:)")
    public convenience init(styles: [Style]? = nil,
                            routingProvider: RoutingProvider,
                            eventsManager: NavigationEventsManager? = nil) {
        self.init(styles: styles,
                  customRoutingProvider: routingProvider,
                  eventsManager: eventsManager,
                  carPlayNavigationViewControllerClass: nil)
    }
    
    /**
     Initializes a new CarPlay manager that manages a connection to the CarPlay interface.
     
     - parameter styles: The styles to display in the CarPlay interface. If this argument is omitted, `DayStyle` and `NightStyle` are displayed by default.
     - parameter customRoutingProvider: The object that customizes routes calculation when the user interacts with the CarPlay interface. `nil` value corresponds to default behavior.
     - parameter eventsManager: The events manager to use during turn-by-turn navigation while connected to CarPlay. If this argument is `nil` or omitted, a standard `NavigationEventsManager` object is used by default.
     */
    public convenience init(styles: [Style]? = nil,
                            customRoutingProvider: RoutingProvider? = nil,
                            eventsManager: NavigationEventsManager? = nil) {
        self.init(styles: styles,
                  customRoutingProvider: customRoutingProvider,
                  eventsManager: eventsManager,
                  carPlayNavigationViewControllerClass: nil)
    }
    
    init(styles: [Style]? = nil,
         customRoutingProvider: RoutingProvider?,
         eventsManager: NavigationEventsManager? = nil,
         carPlayNavigationViewControllerClass: CarPlayNavigationViewController.Type? = nil) {
        self.styles = styles ?? [DayStyle(), NightStyle()]
        self.customRoutingProvider = customRoutingProvider
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
    
    var activeNavigationMapView: NavigationMapView? {
        if let carPlayNavigationViewController = carPlayNavigationViewController,
           let validNavigationMapView = carPlayNavigationViewController.navigationMapView {
            return validNavigationMapView
        } else if let carPlayMapViewController = carPlayMapViewController {
            return carPlayMapViewController.navigationMapView
        } else {
            return nil
        }
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
     The bar button that brings alternative routes selection during navigation.
     */
    public lazy var alternativeRoutesButton: CPBarButton = {
        let altsButton = CPBarButton(type: .text) { [weak self] (button: CPBarButton) in
            guard let template = self?.carPlayNavigationViewController?.alternativesListTemplate() else {
                return
            }
            self?.interfaceController?.pushTemplate(template,
                                                    animated: true)
        }
        
        altsButton.title = NSLocalizedString("CARPLAY_ALTERNATIVES",
                                             bundle: .mapboxNavigation,
                                             value: "Alternatives",
                                             comment: "Title for alternatives selection list button")
        
        return altsButton
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
        carPlayMapViewController.userInfo = eventsManager.userInfo
        carPlayMapViewController.startFreeDriveAutomatically = startFreeDriveAutomatically
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

extension CarPlayManager: CPInterfaceControllerDelegate {
    
    public func templateWillAppear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateWillAppear: template, animated: animated)
        
        if template == interfaceController?.rootTemplate,
           let carPlayMapViewController = carPlayMapViewController {
            carPlayMapViewController.recenterButton.isHidden = true
        }
        
        if let currentActivity = template.currentActivity {
            self.currentActivity = currentActivity
        } else {
            self.currentActivity = nil
        }
    }
    
    public func templateDidAppear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateDidAppear: template, animated: animated)
        
        guard interfaceController?.topTemplate == mainMapTemplate,
              template == interfaceController?.rootTemplate else { return }
        
        removeRoutesFromMap()
    }
    
    public func templateWillDisappear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateWillDisappear: template, animated: animated)
    }
    
    public func templateDidDisappear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateDidDisappear: template, animated: animated)
    }
}

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
        calculate(options) { [weak self] (result) in
            guard let self = self else {
                completionHandler()
                return
            }
            
            self.didCalculate(result,
                              for: options,
                              completionHandler: completionHandler)
        }
    }
    
    /**
     Allows to preview routes for a specific `RouteResponse` object.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes that will be
     previewed.
     */
    @available(*, deprecated, renamed: "previewRoutes(for:)")
    public func previewRoutes(for routeResponse: RouteResponse) {
        let trip = CPTrip(indexedRouteResponse: .init(routeResponse: routeResponse, routeIndex: 0))
        previewRoutes(for: trip)
    }
    
    /**
     Allows to preview routes for a specific `IndexedRouteResponse` object.
     
     - parameter indexedRouteResponse: `IndexedRouteResponse` object, containing selection of routes that will be
     previewed.
     */
    public func previewRoutes(for indexedRouteResponse: IndexedRouteResponse) {
        guard shouldPreviewRoutes(for: indexedRouteResponse) else { return }
        let trip = CPTrip(indexedRouteResponse: indexedRouteResponse)
        previewRoutes(for: trip)
    }
    
    /**
     Allows to cancel routes preview on CarPlay .
     */
    public func cancelRoutesPreview() {
        guard self.indexedRouteResponse != nil else { return }
        var configuration = CarPlayManagerCancelPreviewConfiguration()
        delegate?.carPlayManagerWillCancelPreview(self, configuration: &configuration)
        self.indexedRouteResponse = nil
        mainMapTemplate?.hideTripPreviews()
        if configuration.popToRoot {
            popToRootTemplate(interfaceController: interfaceController, animated: true)
        }
        delegate?.carPlayManagerDidCancelPreview(self)
    }
    
    func shouldPreviewRoutes(for indexedRouteResponse: IndexedRouteResponse) -> Bool {
        guard self.indexedRouteResponse?.currentRoute == indexedRouteResponse.currentRoute else { return true }
        return self.indexedRouteResponse?.routeResponse.routes != indexedRouteResponse.routeResponse.routes
    }
    
    func previewRoutes(for trip: CPTrip) {

        guard let traitCollection = (self.carWindow?.rootViewController as? CarPlayMapViewController)?.traitCollection,
              let interfaceController = interfaceController else {
                  return
              }
        
        let modifiedTrip = delegate?.carPlayManager(self, willPreview: trip) ?? trip
        
        let previewMapTemplate = mapTemplateProvider.mapTemplate(forPreviewing: modifiedTrip,
                                                                 traitCollection: traitCollection,
                                                                 mapDelegate: self)
        
        var previewText = defaultTripPreviewTextConfiguration()
        if let customPreviewText = delegate?.carPlayManager(self, willPreview: modifiedTrip, with: previewText) {
            previewText = customPreviewText
        }
        
        previewMapTemplate.backButton = defaultTripPreviewBackButton()
        previewMapTemplate.showTripPreviews([modifiedTrip], textConfiguration: previewText)
        
        if currentActivity == .previewing {
            if #available(iOS 14.0, *) {
                interfaceController.popTemplate(animated: false) { _, _ in
                    interfaceController.pushTemplate(previewMapTemplate, animated: false)
                }
            } else {
                interfaceController.safePopTemplate(animated: false)
                interfaceController.pushTemplate(previewMapTemplate, animated: false)
            }
        } else {
            interfaceController.pushTemplate(previewMapTemplate, animated: true)
        }
    }
    
    func removeRoutesFromMap() {
        indexedRouteResponse = nil
        guard let navigationMapView = carPlayMapViewController?.navigationMapView else { return }
        navigationMapView.removeRoutes()
        navigationMapView.removeContinuousAlternativesRoutes()
        navigationMapView.removeWaypoints()
    }
    
    func calculate(_ options: RouteOptions, completionHandler: @escaping RoutingProvider.IndexedRouteResponseCompletionHandler) {
        resolvedRoutingProvider.calculateRoutes(options: options, completionHandler: completionHandler)
    }
    
    func didCalculate(_ result: Result<IndexedRouteResponse, DirectionsError>,
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
            popToRootTemplate(interfaceController: interfaceController, animated: true) { _, _ in
                mapTemplate?.present(navigationAlert: alert, animated: true)
            }
            return
        case let .success(indexedRouteResponse):
            previewRoutes(for: indexedRouteResponse)
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
    
    private func defaultTripPreviewBackButton() -> CPBarButton {
        let backButton = CPBarButton(type: .text) { [weak self] (button: CPBarButton) in
            guard let self = self else { return }
            self.cancelRoutesPreview()
        }
        backButton.title = NSLocalizedString("CARPLAY_PREVIEW_BACK",
                                             bundle: .mapboxNavigation,
                                             value: "Back",
                                             comment: "Title for trip preview back button")
        return backButton
    }
}

// MARK: CPMapTemplateDelegate Methods

extension CarPlayManager: CPMapTemplateDelegate {
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            startedTrip trip: CPTrip,
                            using routeChoice: CPRouteChoice) {
        guard let interfaceController = interfaceController,
              let carPlayMapViewController = carPlayMapViewController else {
                  return
              }
        
        guard let indexedRouteResponse = routeChoice.indexedRouteResponse else {
            preconditionFailure("CPRouteChoice should contain `IndexedRouteResponseUserInfo` struct.")
        }

        mapTemplate.hideTripPreviews()
        
        let desiredSimulationMode: SimulationMode = simulatesLocations ? .always : .inTunnels
        
        var navigationServiceWithRouteOptions: (() -> NavigationService?)? = nil
        if case let .route(routeOptions) = indexedRouteResponse.routeResponse.options {
            navigationServiceWithRouteOptions = {
                (self.delegate as CarPlayManagerDelegateDeprecations?)?
                    .carPlayManager(self,
                                    navigationServiceFor: indexedRouteResponse.routeResponse,
                                    routeIndex: indexedRouteResponse.routeIndex,
                                    routeOptions: routeOptions,
                                    desiredSimulationMode: desiredSimulationMode)
            }
        }
        
        let navigationService = self.navigationService ??
        delegate?.carPlayManager(self,
                                 navigationServiceFor: indexedRouteResponse,
                                 desiredSimulationMode: desiredSimulationMode) ??
        navigationServiceWithRouteOptions?() ??
        MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                customRoutingProvider: customRoutingProvider,
                                credentials: NavigationSettings.shared.directions.credentials,
                                simulating: desiredSimulationMode)
        
        // Store newly created `MapboxNavigationService`.
        self.navigationService = navigationService

        if simulatesLocations {
            navigationService.simulationSpeedMultiplier = simulatedSpeedMultiplier
        }
        popToRootTemplate(interfaceController: interfaceController, animated: false) { [self] _, _ in
            let navigationMapTemplate = self.navigationMapTemplate()
            setRootTemplate(interfaceController: interfaceController,
                            rootTemplate: navigationMapTemplate,
                            animated: true) { [self] _, _ in
                
                let carPlayNavigationViewController = carPlayNavigationViewControllerType.init(navigationService: navigationService,
                                                                                               mapTemplate: navigationMapTemplate,
                                                                                               interfaceController: interfaceController,
                                                                                               manager: self,
                                                                                               styles: styles)
                carPlayNavigationViewController.startNavigationSession(for: trip)
                carPlayNavigationViewController.delegate = self
                carPlayNavigationViewController.modalPresentationStyle = .fullScreen
                self.carPlayNavigationViewController = carPlayNavigationViewController
                
                carPlayNavigationViewController.loadViewIfNeeded()
                delegate?.carPlayManager(self, willPresent: carPlayNavigationViewController)
                
                carPlayMapViewController.present(carPlayNavigationViewController, animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.carPlayManager(self, didPresent: carPlayNavigationViewController)
                }
                
                self.removeRoutesFromMap()
            }
        }
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
        
        guard let indexedRouteResponse = routeChoice.indexedRouteResponse,
              let route = indexedRouteResponse.currentRoute,
              var routes = indexedRouteResponse.routeResponse.routes else {
                  preconditionFailure("CPRouteChoice should contain `IndexedRouteResponseUserInfo` struct.")
              }
        
        let estimates = CPTravelEstimates(distanceRemaining: Measurement(distance: route.distance).localized(),
                                          timeRemaining: route.expectedTravelTime)
        mapTemplate.updateEstimates(estimates, for: trip)
        
        if let index = routes.firstIndex(where: { $0 === route }) {
            routes.insert(routes.remove(at: index), at: 0)
        }
        
        let navigationMapView = carPlayMapViewController.navigationMapView
        let cameraOptions = CameraOptions(bearing: 0.0)
        navigationMapView.showcase(routes,
                                   routesPresentationStyle: .all(shouldFit: true, cameraOptions: cameraOptions),
                                   animated: true)
        self.indexedRouteResponse = indexedRouteResponse
        delegate?.carPlayManager(self, selectedPreviewFor: trip, using: routeChoice)
    }

    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController = carPlayMapViewController else {
            return
        }
        let navigationMapView = carPlayMapViewController.navigationMapView
        self.removeRoutesFromMap()
        if let passiveLocationProvider = navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider {
            passiveLocationProvider.locationManager.resumeTripSession()
            carPlayMapViewController.subscribeForFreeDriveNotifications()
        }
        delegate?.carPlayManagerDidEndNavigation(self)
        delegate?.carPlayManagerDidEndNavigation(self, byCanceling: false)
    }
    
    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        // Whenever panning starts - stop any navigation camera updates.
        activeNavigationMapView?.navigationCamera.stop()
        delegate?.carPlayManager(self, didBeginPanGesture: mapTemplate)
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        // After panning is stopped - allow navigation bar dismissal.
        mapTemplate.automaticallyHidesNavigationBar = true
        delegate?.carPlayManager(self, didEndPanGesture: mapTemplate)
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
        delegate?.carPlayManager(self, didShowPanningInterface: mapTemplate)
    }
    
    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        if let carPlayMapViewController = carPlayMapViewController {
            let shouldShowRecenterButton = carPlayMapViewController.navigationMapView.navigationCamera.state == .idle
            carPlayMapViewController.recenterButton.isHidden = !shouldShowRecenterButton
        }

        delegate?.carPlayManager(self, willDismissPanningInterface: mapTemplate)
    }
    
    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let currentActivity = mapTemplate.currentActivity else { return }
        
        self.currentActivity = currentActivity
        
        updateNavigationButtons(for: mapTemplate)
        delegate?.carPlayManager(self, didDismissPanningInterface: mapTemplate)
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            didUpdatePanGestureWithTranslation translation: CGPoint,
                            velocity: CGPoint) {
        // Map view panning is allowed in all states except routes preview.
        if currentActivity == .previewing {
            return
        }
        
        // Continuously prevent navigation bar hiding whenever panning occurs.
        mapTemplate.automaticallyHidesNavigationBar = false
        
        updatePan(by: translation, mapTemplate: mapTemplate)
    }
    
    private func updatePan(by offset: CGPoint, mapTemplate: CPMapTemplate) {
        guard let navigationMapView = activeNavigationMapView else { return }

        navigationMapView.mapView.mapboxMap.setCamera(to: dragCameraOptions(with: offset, in: navigationMapView))
    }

    private func dragCameraOptions(with offset: CGPoint, in navigationMapView: NavigationMapView) -> CameraOptions {
        let contentFrame = navigationMapView.bounds.inset(by: navigationMapView.mapView.safeAreaInsets)
        let centerPoint = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x + offset.x, y: centerPoint.y + offset.y)

        return navigationMapView.mapView.mapboxMap.dragCameraOptions(from: centerPoint, to: endCameraPoint)
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        // In case if `CarPlayManager.carPlayNavigationViewController` is not `nil`, it means that
        // active-guidance navigation is currently in progress. Is so, panning should be applied for
        // `NavigationMapView` instance there.
        guard let navigationMapView = activeNavigationMapView else { return }
        
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

    private func popToRootTemplate(interfaceController: CPInterfaceController?,
                                   animated: Bool,
                                   completion: ((Bool, Error?) -> Void)? = nil) {
        guard let interfaceController = interfaceController,
              interfaceController.templates.count > 1 else {
            completion?(false, nil)
            return
        }
        
        if #available(iOS 14.0, *) {
            interfaceController.popToRootTemplate(animated: animated, completion: completion)
        } else {
            interfaceController.popToRootTemplate(animated: animated)
            completion?(true, nil)
        }
    }

    private func setRootTemplate(interfaceController: CPInterfaceController?,
                                 rootTemplate: CPTemplate,
                                 animated: Bool,
                                 completion: ((Bool, Error?) -> Void)? = nil) {
        guard let interfaceController = interfaceController else {
            completion?(false, nil)
            return
        }
        
        if #available(iOS 14.0, *) {
            interfaceController.setRootTemplate(rootTemplate,
                                                animated: animated,
                                                completion: completion)
        } else {
            interfaceController.setRootTemplate(rootTemplate, animated: animated)
            completion?(true, nil)
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
        guard let currentActivity = mapTemplate.currentActivity else { return }

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
            mapTemplate.leadingNavigationBarButtons = [muteButton, alternativeRoutesButton]
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
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            shouldShowNotificationFor maneuver: CPManeuver) -> Bool {
        return delegate?.carPlayManager(self,
                                        shouldShowNotificationFor: maneuver,
                                        in: mapTemplate) ?? false
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            shouldShowNotificationFor navigationAlert: CPNavigationAlert) -> Bool {
        return delegate?.carPlayManager(self,
                                        shouldShowNotificationFor: navigationAlert,
                                        in: mapTemplate) ?? false
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate,
                            shouldUpdateNotificationFor maneuver: CPManeuver,
                            with travelEstimates: CPTravelEstimates) -> Bool {
        return delegate?.carPlayManager(self,
                                        shouldUpdateNotificationFor: maneuver,
                                        with: travelEstimates,
                                        in: mapTemplate) ?? false
    }
}

// MARK: CarPlayNavigationViewControllerDelegate Methods

extension CarPlayManager: CarPlayNavigationViewControllerDelegate {
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController, 
                                                waypointCircleLayerWithIdentifier identifier: String,
                                                sourceIdentifier: String) -> MapboxMaps.CircleLayer? {
        delegate?.carPlayManager(self, waypointCircleLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController, 
                                                waypointSymbolLayerWithIdentifier identifier: String,
                                                sourceIdentifier: String) -> SymbolLayer? {
        delegate?.carPlayManager(self, waypointSymbolLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
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

        setRootTemplate(interfaceController: interfaceController,
                        rootTemplate: mapTemplate,
                        animated: true) { [self] _, _ in
            
            if let passiveLocationProvider = navigationMapView?.mapView.location.locationProvider as? PassiveLocationProvider {
                passiveLocationProvider.locationManager.resumeTripSession()
                carPlayMapViewController?.subscribeForFreeDriveNotifications()
            }
            
            self.carPlayNavigationViewController = nil
            delegate?.carPlayManagerDidEndNavigation(self)
            delegate?.carPlayManagerDidEndNavigation(self, byCanceling: canceled)
        }
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
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                routeLineLayerWithIdentifier identifier: String,
                                                sourceIdentifier: String) -> LineLayer? {
        return delegate?.carPlayManager(self,
                                        routeLineLayerWithIdentifier: identifier,
                                        sourceIdentifier: sourceIdentifier,
                                        for: carPlayNavigationViewController)
    }
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                routeCasingLineLayerWithIdentifier identifier: String,
                                                sourceIdentifier: String) -> LineLayer? {
        return delegate?.carPlayManager(self,
                                        routeCasingLineLayerWithIdentifier: identifier,
                                        sourceIdentifier: sourceIdentifier,
                                        for: carPlayNavigationViewController)
    }
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                routeRestrictedAreasLineLayerWithIdentifier identifier: String,
                                                sourceIdentifier: String) -> LineLayer? {
        return delegate?.carPlayManager(self,
                                        routeRestrictedAreasLineLayerWithIdentifier: identifier,
                                        sourceIdentifier: sourceIdentifier,
                                        for: carPlayNavigationViewController)
    }
    
    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                willAdd layer: Layer) -> Layer? {
        return delegate?.carPlayManager(self,
                                        willAdd: layer,
                                        for: carPlayNavigationViewController)
    }
}

// MARK: CarPlayMapViewControllerDelegate Methods

extension CarPlayManager: CarPlayMapViewControllerDelegate {

    public func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController, 
                                                guidanceBackgroundColorFor style: UIUserInterfaceStyle) -> UIColor? {
        delegate?.carPlayNavigationViewController(self, guidanceBackgroundColorFor: style)
    }

    public func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                         didAdd finalDestinationAnnotation: PointAnnotation,
                                         pointAnnotationManager: PointAnnotationManager) {
        delegate?.carPlayManager(self,
                                 didAdd: finalDestinationAnnotation,
                                 to: carPlayMapViewController,
                                 pointAnnotationManager: pointAnnotationManager)
    }
    
    public func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                         routeLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer? {
        delegate?.carPlayManager(self,
                                 routeLineLayerWithIdentifier: identifier,
                                 sourceIdentifier: sourceIdentifier,
                                 for: carPlayMapViewController)
    }
    
    public func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                         routeCasingLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer? {
        delegate?.carPlayManager(self,
                                 routeCasingLineLayerWithIdentifier: identifier,
                                 sourceIdentifier: sourceIdentifier,
                                 for: carPlayMapViewController)
    }
    
    public func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                         routeRestrictedAreasLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer? {
        delegate?.carPlayManager(self,
                                 routeRestrictedAreasLineLayerWithIdentifier: identifier,
                                 sourceIdentifier: sourceIdentifier,
                                 for: carPlayMapViewController)
    }
    
    public func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                         willAdd layer: Layer) -> Layer? {
        delegate?.carPlayManager(self,
                                 willAdd: layer,
                                 for: carPlayMapViewController)
    }
}

// MARK: MapTemplateProviderDelegate Methods

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
        carPlayMapViewController.startFreeDriveAutomatically = startFreeDriveAutomatically
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
        indexedRouteResponse = nil
    }
}

// MARK: CarPlayManager Constants

extension CarPlayManager {
    
    static let currentActivityKey = "com.mapbox.navigation.currentActivity"
}
