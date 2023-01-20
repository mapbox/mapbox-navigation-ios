import Foundation
import MapboxDirections
import MapboxCoreNavigation
@_spi(Restricted) import MapboxMaps

#if canImport(CarPlay)
import CarPlay

let CarPlayAlternativeIDKey: String = "MBCarPlayAlternativeID"

/**
 `CarPlayNavigationViewController` is a fully-featured turn-by-turn navigation UI for CarPlay.
 
 - seealso: `NavigationViewController`
 */
@available(iOS 12.0, *)
open class CarPlayNavigationViewController: UIViewController, BuildingHighlighting {
    
    // MARK: Child Views and Styling Configuration
    
    /**
     A view indicating what direction the vehicle is traveling towards, snapped
     to eight cardinal directions in steps of 45°.
     
     This view is hidden by default.
     */
    public var compassView: CarPlayCompassView!
    
    /**
     A view that displays the current speed limit.
     */
    public var speedLimitView: SpeedLimitView!
    
    /**
     A view that displays the current road name.
     */
    public var wayNameView: WayNameView!
    
    /**
     Session configuration that is used to track `CPContentStyle` related changes.
     */
    var sessionConfiguration: CPSessionConfiguration!
    
    /**
     The interface styles available for display.
     
     These are the styles available to the view controller’s internal `StyleManager` object. In CarPlay, `Style` objects primarily affect the appearance of the map, not guidance-related overlay views.
     */
    public var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }
    
    /**
     Controls whether the main route style layer and its casing disappears
     as the user location puck travels over it. Defaults to `false`.
     
     If `true`, the part of the route that has been traversed will be
     rendered with full transparency, to give the illusion of a
     disappearing route. To customize the color that appears on the
     traversed section of a route, override the `traversedRouteColor` property
     for the `NavigationMapView.appearance()`.
     */
    public var routeLineTracksTraversal: Bool = false {
        didSet {
            navigationMapView?.routeLineTracksTraversal = routeLineTracksTraversal
        }
    }
    
    /**
     Toggles displaying alternative routes.
     
     If enabled, view will draw actual alternative route lines on the map.
     Default value is `true`.
     */
    public var showsContinuousAlternatives: Bool = true {
        didSet {
            updateContinuousAlternatives()
        }
    }
    
    /**
     A Boolean value that determines whether the map annotates the intersections on current step during active navigation.
     
     If `true`, the map would display an icon of a traffic control device on the intersection,
     such as traffic signal, stop sign, yield sign, or railroad crossing.
     Defaults to `true`.
     */
    public var annotatesIntersectionsAlongRoute: Bool = true {
        didSet {
            updateIntersectionsAlongRoute()
        }
    }
    
    /**
     `AlternativeRoute`s user might take during this trip to reach the destination using another road.
     
     Array contents are updated automatically duting the trip. Alternative routes may be slower or longer then the main route.
     To get updates, subscribe to `Notification.Name.routeControllerDidUpdateAlternatives` notification.
     */
    public var continuousAlternatives: [AlternativeRoute] {
        navigationService.router.continuousAlternatives
    }
    
    private func format(value: LocationDistance,
                        labels: (decreasing: String, increasing: String, equal: String)) -> String {
        switch value {
        case ..<0:
            return labels.decreasing
        case 0:
            return labels.equal
        default:
            return labels.increasing
        }
    }
    
    func alternativesListTemplate() -> CPListTemplate {
        var variants: [CPListSection] = []
        let distanceFormatter = DistanceFormatter()
        self.continuousAlternatives.forEach { alternative in
            guard let title = alternative.indexedRouteResponse.currentRoute?.description else {
                return
            }
            distanceFormatter.measurementFormatter.numberFormatter.negativePrefix = ""
            let distanceDeltaText = distanceFormatter.string(from: alternative.distanceDelta)
            let distanceDelta = format(value: alternative.distanceDelta,
                                       labels: (decreasing: String.localizedStringWithFormat(NSLocalizedString("SHORTER_ALTERNATIVE",
                                                                                                               bundle: .mapboxNavigation,
                                                                                                               value: "%@ shorter",
                                                                                                               comment: "Alternatives selection note about a shorter route distance in any unit."),
                                                                                             distanceDeltaText),
                                                increasing: String.localizedStringWithFormat(NSLocalizedString("LONGER_ALTERNATIVE",
                                                                                                               bundle: .mapboxNavigation,
                                                                                                               value: "%@ longer",
                                                                                                               comment: "Alternatives selection note about a longer route distance in any unit."),
                                                                                             distanceDeltaText),
                                                equal: NSLocalizedString("SAME_DISTANCE",
                                                                         bundle: .mapboxNavigation,
                                                                         value: "Same distance",
                                                                         comment: "Alternatives selection note about equal travel distance.")))
            let timeDeltaText = DateComponentsFormatter.travelTimeString(alternative.expectedTravelTimeDelta, signed: false, unitStyle: .full)
            let timeDelta = format(value: alternative.expectedTravelTimeDelta,
                                   labels: (decreasing: String.localizedStringWithFormat(NSLocalizedString("FASTER_ALTERNATIVE",
                                                                                                           bundle: .mapboxNavigation,
                                                                                                           value: "%@ faster",
                                                                                                           comment: "Alternatives selection note about a faster route time interval in any unit."),
                                                                                         timeDeltaText),
                                            increasing: String.localizedStringWithFormat(NSLocalizedString("SLOWER_ALTERNATIVE",
                                                                                                           bundle: .mapboxNavigation,
                                                                                                           value: "%@ slower",
                                                                                                           comment: "Alternatives selection note about a slower route time interval in any unit."),
                                                                                         timeDeltaText),
                                            equal: NSLocalizedString("SAME_TIME",
                                                                     bundle: .mapboxNavigation,
                                                                     value: "Same time",
                                                                     comment: "Alternatives selection note about equal travel time.")))
            
            let items: [CPListItem] = [CPListItem(text: String.localizedStringWithFormat(NSLocalizedString("ALTERNATIVE_NOTES",
                                                                                                           bundle: .mapboxNavigation,
                                                                                                           value: "%1$@ / %2$@",
                                                                                                           comment: "Combined alternatives selection notes about duration (first slot position) and distance (second slot position) delta."),
                                                                                         timeDelta,
                                                                                         distanceDelta),
                                                  detailText: nil)]
            items.forEach { (item: CPListItem) -> Void in
                item.userInfo = [CarPlayAlternativeIDKey: alternative.id]
            }
            let section = CPListSection(items: items,
                                        header: title,
                                        sectionIndexTitle: nil)
            variants.append(section)
        }
        
        let alternativesTitle = NSLocalizedString("CARPLAY_ALTERNATIVES",
                                                  bundle: .mapboxNavigation,
                                                  value: "Alternatives",
                                                  comment: "Title for alternatives selection list button")
        
        let template = CPListTemplate(title: alternativesTitle,
                                      sections: variants)
        template.delegate = self
        return template
    }
    
    /**
     Controls whether night style will be used whenever traversing through a tunnel. Defaults to `true`.
     */
    public var usesNightStyleWhileInTunnel: Bool = true
    
    /**
     Controls the styling of CarPlayNavigationViewController and its components.

     The style can be modified programmatically by using `StyleManager.applyStyle(type:)`.
     */
    public private(set) var styleManager: StyleManager?
    
    /**
     Allows to control highlighting of the destination building on arrival. By default destination buildings will not be highlighted.
     */
    public var waypointStyle: WaypointStyle = .annotation
    
    var approachingDestinationThreshold: CLLocationDistance = DefaultApproachingDestinationThresholdDistance
    var passedApproachingDestinationThreshold: Bool = false
    var currentLeg: RouteLeg?
    var buildingWasFound: Bool = false
    
    var mapTemplate: CPMapTemplate
    var carInterfaceController: CPInterfaceController
    
    private var isTraversingTunnel = false
    
    private var safeTrailingSpeedLimitViewConstraint: NSLayoutConstraint!
    private var trailingSpeedLimitViewConstraint: NSLayoutConstraint!
    
    private var safeTrailingCompassViewConstraint: NSLayoutConstraint!
    private var trailingCompassViewConstraint: NSLayoutConstraint!

    func setupOrnaments() {
        let compassView = CarPlayCompassView()
        view.addSubview(compassView)
        
        compassView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 8).isActive = true
        safeTrailingCompassViewConstraint = compassView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                                                  constant: -8)
        trailingCompassViewConstraint = compassView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                                              constant: -8)
        self.compassView = compassView
        
        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)
        
        speedLimitView.topAnchor.constraint(equalTo: compassView.bottomAnchor, constant: 8).isActive = true
        safeTrailingSpeedLimitViewConstraint = speedLimitView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                                                        constant: -8)
        trailingSpeedLimitViewConstraint = speedLimitView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                                                    constant: -8)
        speedLimitView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.speedLimitView = speedLimitView
        
        let wayNameView: WayNameView = .forAutoLayout()
        wayNameView.containerView.isHidden = true
        wayNameView.containerView.clipsToBounds = true
        wayNameView.label.textAlignment = .center
        view.addSubview(wayNameView)
        
        NSLayoutConstraint.activate([
            wayNameView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -8),
            wayNameView.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor),
            wayNameView.widthAnchor.constraint(lessThanOrEqualTo: view.safeWidthAnchor, multiplier: 0.95),
            wayNameView.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        
        self.wayNameView = wayNameView
    }
    
    func setupStyleManager() {
        styleManager = StyleManager(traitCollection: UITraitCollection(userInterfaceIdiom: .carPlay))
        styleManager?.delegate = self
        styleManager?.styles = self.styles
    }
    
    /**
     Updates `CPMapTemplate.tripEstimateStyle` and `CPMapTemplate.guidanceBackgroundColor`.
     */
    func updateMapTemplateStyle() {
        var currentUserInterfaceStyle = traitCollection.userInterfaceStyle
        // Regardless of the user interface style that was set in CarPlay settings style that is
        // currently used in `StyleManager` will have precedence. Precedence of the style over
        // trait collection is required for custom cases (e.g. when user is driving through the tunnel).
        if usesNightStyleWhileInTunnel,
           isTraversingTunnel,
           let styleType = styleManager?.currentStyleType {
            switch styleType {
            case .day:
                currentUserInterfaceStyle = .light
            case .night:
                currentUserInterfaceStyle = .dark
            }
        }
        
        switch currentUserInterfaceStyle {
        case .dark:
            mapTemplate.guidanceBackgroundColor = .black
            mapTemplate.tripEstimateStyle = .dark
        default:
            mapTemplate.guidanceBackgroundColor = .white
            mapTemplate.tripEstimateStyle = .light
        }
    }
    
    // MARK: Collecting User Feedback
    
    /**
     Provides methods for creating and sending user feedback.
     */
    public var eventsManager: NavigationEventsManager {
        return navigationService.eventsManager
    }
    
    var carFeedbackTemplate: CPGridTemplate!
    
    /**
     Shows the interface for providing feedback about the route.
     */
    public func showFeedback() {
        carInterfaceController.pushTemplate(self.carFeedbackTemplate, animated: true)
    }
    
    func createFeedbackUI() -> CPGridTemplate {
        let feedbackItems: [FeedbackItem] = [
            ActiveNavigationFeedbackType.looksIncorrect(subtype: nil),
            ActiveNavigationFeedbackType.confusingAudio(subtype: nil),
            ActiveNavigationFeedbackType.illegalRoute(subtype: nil),
            ActiveNavigationFeedbackType.roadClosure(subtype: nil),
            ActiveNavigationFeedbackType.routeQuality(subtype: nil),
            ActiveNavigationFeedbackType.positioning
        ].map { $0.generateFeedbackItem() }
        
        let feedbackButtonHandler: (_ : CPGridButton) -> Void = { [weak self] (button) in
            guard let self = self else { return }
            self.carInterfaceController.safePopTemplate(animated: true)
            
            guard let feedback = self.eventsManager.createFeedback() else { return }
            let foundItem = feedbackItems.filter { $0.image == button.image }
            guard let feedbackItem = foundItem.first else { return }
            self.eventsManager.sendFeedback(feedback, type: feedbackItem.type)
            
            let dismissTitle = NSLocalizedString("CARPLAY_DISMISS",
                                                 bundle: .mapboxNavigation,
                                                 value: "Dismiss",
                                                 comment: "Title for dismiss button")
            
            let submittedTitle = NSLocalizedString("CARPLAY_SUBMITTED_FEEDBACK",
                                                   bundle: .mapboxNavigation,
                                                   value: "Submitted",
                                                   comment: "Alert title that shows when feedback has been submitted")
            
            let action = CPAlertAction(title: dismissTitle,
                                       style: .default,
                                       handler: { _ in })
            
            let alert = CPNavigationAlert(titleVariants: [submittedTitle],
                                          subtitleVariants: nil,
                                          imageSet: nil,
                                          primaryAction: action,
                                          secondaryAction: nil,
                                          duration: 2.5)
            
            self.mapTemplate.present(navigationAlert: alert, animated: true)
        }
        
        let buttons: [CPGridButton] = feedbackItems.map {
            return CPGridButton(titleVariants: [$0.title.components(separatedBy: "\n").joined(separator: " ")],
                                image: $0.image,
                                handler: feedbackButtonHandler)
        }
        
        let gridTitle = NSLocalizedString("CARPLAY_FEEDBACK",
                                          bundle: .mapboxNavigation,
                                          value: "Feedback",
                                          comment: "Title for feedback template in CarPlay")
        
        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }
    
    func endOfRouteFeedbackTemplate() -> CPGridTemplate {
        let buttonHandler: (_: CPGridButton) -> Void = { [weak self] (button) in
            guard let self = self else { return }
            
            if let title = button.titleVariants.first {
                let rating = Int(title.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                let endOfRouteFeedback = EndOfRouteFeedback(rating: rating, comment: nil)
                self.navigationService.endNavigation(feedback: endOfRouteFeedback)
            }
            
            self.carInterfaceController.safePopTemplate(animated: true)
            self.exitNavigation()
        }
        
        var buttons: [CPGridButton] = []
        let starImage = UIImage(named: "star",
                                in: .mapboxNavigation,
                                compatibleWith: nil)!
        
        for rating in 1...5 {
            let title = NSLocalizedString("RATING_STARS_FORMAT",
                                          bundle: .mapboxNavigation,
                                          value: "%ld star(s) set.",
                                          comment: "Format for accessibility value of label indicating the existing rating; 1 = number of stars")
            let titleVariant = String.localizedStringWithFormat(title, rating)
            let button = CPGridButton(titleVariants: [titleVariant],
                                      image: starImage,
                                      handler: buttonHandler)
            buttons.append(button)
        }
        
        let gridTitle = NSLocalizedString("CARPLAY_RATE_RIDE",
                                          bundle: .mapboxNavigation,
                                          value: "Rate your ride",
                                          comment: "Title for rating template in CarPlay")
        
        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }
    
    func presentArrivalUI() {
        let arrivalTitle = NSLocalizedString("CARPLAY_ARRIVED",
                                             bundle: .mapboxNavigation,
                                             value: "You have arrived",
                                             comment: "Title on arrival action sheet")
        
        let arrivalMessage = NSLocalizedString("CARPLAY_ARRIVED_MESSAGE",
                                               bundle: .mapboxNavigation,
                                               value: "What would you like to do?",
                                               comment: "Message on arrival action sheet")
        
        let exitTitle = NSLocalizedString("CARPLAY_EXIT_NAVIGATION",
                                          bundle: .mapboxNavigation,
                                          value: "Exit navigation",
                                          comment: "Title on the exit button in the arrival form")
        
        let exitAction = CPAlertAction(title: exitTitle, style: .cancel) { (action) in
            self.exitNavigation()
            self.dismiss(animated: true)
        }
        
        let rateTitle = NSLocalizedString("CARPLAY_RATE_TRIP",
                                          bundle: .mapboxNavigation,
                                          value: "Rate your trip",
                                          comment: "Title on rate button in CarPlay")
        
        let rateAction = CPAlertAction(title: rateTitle, style: .default) { (action) in
            self.carInterfaceController.pushTemplate(self.endOfRouteFeedbackTemplate(), animated: true)
        }
        
        let alert = CPActionSheetTemplate(title: arrivalTitle,
                                          message: arrivalMessage,
                                          actions: [rateAction, exitAction])
        
        carInterfaceController.dismissTemplate(animated: true)
        carInterfaceController.presentTemplate(alert, animated: true)
    }
    
    // MARK: Navigating the Route
    
    /**
     The view controller’s delegate, that is used by the `CarPlayManager`.
     
     Do not overwrite this property and use `CarPlayManagerDelegate` methods directly.
     */
    public weak var delegate: CarPlayNavigationViewControllerDelegate?
    
    /**
     `CarPlayManager` instance, which contains main `UIWindow` content and is used by
     `CarPlayNavigationViewController` for presentation.
     */
    public var carPlayManager: CarPlayManager
    
    /**
     Provides all routing logic for the user.
     
     See `NavigationService` for more information.
     */
    public var navigationService: NavigationService
    
    /**
     The map view showing the route and the user’s location.
     */
    public fileprivate(set) var navigationMapView: NavigationMapView?
    
    var carSession: CPNavigationSession!
    var currentLegIndexMapped: Int = 0

    /**
     Begins a navigation session along the given trip.
     
     - parameter trip: The trip to begin navigating along.
     */
    public func startNavigationSession(for trip: CPTrip) {
        carSession = mapTemplate.startNavigationSession(for: trip)
    }
    
    /**
     Ends the current navigation session.
     
     - parameter canceled: A Boolean value indicating whether this method is being called because the user intends to cancel the trip, as opposed to letting it run to completion.
     */
    public func exitNavigation(byCanceling canceled: Bool = false) {
        carSession.finishTrip()
        
        self.delegate?.carPlayNavigationViewControllerWillDismiss(self, byCanceling: canceled)
        
        dismiss(animated: true) {
            self.delegate?.carPlayNavigationViewControllerDidDismiss(self, byCanceling: canceled)
        }
    }
    
    /**
     Creates a new CarPlay navigation view controller for the given route controller and user interface.
     
     - parameter navigationService: The navigation service managing location updates for the navigation session.
     - parameter mapTemplate: The map template visible during the navigation session.
     - parameter interfaceController: The interface controller for CarPlay.
     - parameter manager: The manager for CarPlay.
     - parameter styles: The interface styles that the view controller’s internal `StyleManager` object can select from for display.
     
     - postcondition: Call `startNavigationSession(for:)` after initializing this object to begin navigation.
     */
    public required init(navigationService: NavigationService,
                         mapTemplate: CPMapTemplate,
                         interfaceController: CPInterfaceController,
                         manager: CarPlayManager,
                         styles: [Style]? = nil) {
        self.navigationService = navigationService
        self.mapTemplate = mapTemplate
        self.carInterfaceController = interfaceController
        self.carPlayManager = manager
        self.styles = styles ?? [DayStyle(), NightStyle()]
        
        super.init(nibName: nil, bundle: nil)
        carFeedbackTemplate = createFeedbackUI()
        
        sessionConfiguration = CPSessionConfiguration(delegate: self)
    }
    
    public required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        suspendNotifications()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOrnaments()
        setupNavigationMapView()
        setupStyleManager()
        
        observeNotifications(navigationService)
        navigationService.start()
        carPlayManager.delegate?.carPlayManager(carPlayManager, didBeginNavigationWith: navigationService)
        currentLegIndexMapped = navigationService.router.routeProgress.legIndex
        navigationMapView?.simulatesLocation = navigationService.locationManager.simulatesLocation
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 13.0, *) {
            applyStyleIfNeeded(sessionConfiguration.contentStyle)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspendNotifications()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateMapTemplateStyle()
            updateManeuvers(navigationService.routeProgress)
        }
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // Trigger update of view constraints to correctly position views like `SpeedLimitView` and
        // `CarPlayCompassView`.
        view.setNeedsUpdateConstraints()
    }
    
    @available(iOS 13.0, *)
    func applyStyleIfNeeded(_ contentStyle: CPContentStyle) {
        if contentStyle.contains(.dark) {
            styleManager?.applyStyle(type: .night)
        } else if contentStyle.contains(.light) {
            styleManager?.applyStyle(type: .day)
        }
    }
    
    public override func updateViewConstraints() {
        // Since there is no ability to detect current driving side mode of the CarPlay head-unit,
        // two separate `NSLayoutConstraint` objects are used to prevent `SpeedLimitView` and
        // `CarPlayCompassView` disappearance:
        // - first one is used when driving on the right side of the road, in this case guidance and trip
        // estimate panels will be on the right.
        // - second one is used when driving on the left side of the road, in this case guidance and trip
        // estimate panels will be on the left.
        // Similar check is performed in `CarPlayMapViewController`.
        if view.safeAreaInsets.right > 38.0 {
            safeTrailingCompassViewConstraint.isActive = true
            trailingCompassViewConstraint.isActive = false
            
            safeTrailingSpeedLimitViewConstraint.isActive = true
            trailingSpeedLimitViewConstraint.isActive = false
        } else {
            safeTrailingCompassViewConstraint.isActive = false
            trailingCompassViewConstraint.isActive = true
            
            safeTrailingSpeedLimitViewConstraint.isActive = false
            trailingSpeedLimitViewConstraint.isActive = true
        }
        
        super.updateViewConstraints()
    }
    
    func setupNavigationMapView() {
        let navigationMapView = NavigationMapView(frame: view.bounds, navigationCameraType: .carPlay)
        navigationMapView.userLocationStyle = .courseView()
        navigationMapView.delegate = self
        navigationMapView.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationMapView.mapView,
                                                                                             viewportDataSourceType: .active)
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Reapply runtime styling changes each time the style changes.
        navigationMapView.mapView.mapboxMap.onEvery(event: .styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.navigationMapView?.localizeLabels()
            self.navigationMapView?.mapView.showsTraffic = false
            self.updateRouteOnMap()
        }
        
        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
        navigationMapView.mapView.ornaments.options.logo.visibility = .hidden
        navigationMapView.mapView.ornaments.options.attributionButton.visibility = .hidden
        
        navigationMapView.navigationCamera.follow()

        view.insertSubview(navigationMapView, at: 0)
        navigationMapView.pinInSuperview()
        
        self.navigationMapView = navigationMapView
        
        if let coordinate = navigationService.routeProgress.route.shape?.coordinates.first {
            navigationMapView.setInitialCamera(coordinate)
        }
        
        updateContinuousAlternatives()
    }
    
    // MARK: Notifications Observer Methods
    
    func observeNotifications(_ service: NavigationService) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rerouted(_:)),
                                               name: .routeControllerDidReroute,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh(_:)),
                                               name: .routeControllerDidRefreshRoute,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(visualInstructionDidChange(_:)),
                                               name: .routeControllerDidPassVisualInstructionPoint,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(simulationStateDidChange(_:)),
                                               name: .navigationServiceSimulationDidChange,
                                               object: service)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdateRoadNameFromStatus),
                                               name: .currentRoadNameDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(continuousAlternativesDidChange),
                                               name: .routeControllerDidUpdateAlternatives,
                                               object: service.router)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidReroute,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidRefreshRoute,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidPassVisualInstructionPoint,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationServiceSimulationDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .currentRoadNameDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidUpdateAlternatives,
                                                  object: nil)
    }
    
    @objc func continuousAlternativesDidChange(_ notification: NSNotification) {
        updateContinuousAlternatives()
    }
    
    func updateContinuousAlternatives() {
        if showsContinuousAlternatives {
            navigationMapView?.show(continuousAlternatives: continuousAlternatives)
        } else {
            navigationMapView?.removeContinuousAlternativesRoutes()
        }
    }
    
    @objc func visualInstructionDidChange(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress else {
            assertionFailure("RouteProgress should be available.")
            return
        }
        
        updateManeuvers(routeProgress)
        navigationMapView?.showWaypoints(on: routeProgress.route)
        
        if routeProgress.currentLegProgress.followOnStep != nil {
            navigationMapView?.addArrow(route: routeProgress.route,
                                        legIndex: routeProgress.legIndex,
                                        stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            navigationMapView?.removeArrow()
        }
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation else {
            assertionFailure("RouteProgress and CLLocation should be available.")
            return
        }
        
        // Check to see if we're in a tunnel.
        checkTunnelState(at: location, along: routeProgress)
        
        attemptToHighlightBuildings(routeProgress, navigationMapView: navigationMapView)
        
        let legIndex = routeProgress.legIndex
        
        // Update the user puck
        navigationMapView?.updatePreferredFrameRate(for: routeProgress)
        navigationMapView?.moveUserLocation(to: location, animated: true)
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        
        let routeDistance = Measurement(distance: routeProgress.distanceRemaining).localized()
        let routeEstimates = CPTravelEstimates(distanceRemaining: routeDistance, timeRemaining: routeProgress.durationRemaining)
        mapTemplate.update(routeEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let stepDistance = Measurement(distance: stepProgress.distanceRemaining).localized()
        let stepEstimates = CPTravelEstimates(distanceRemaining: stepDistance, timeRemaining: stepProgress.durationRemaining)
        carSession.updateEstimates(stepEstimates, for: maneuver)
        
        if let compassView = self.compassView, !compassView.isHidden {
            compassView.course = location.course
        }
        
        if let speedLimitView = speedLimitView {
            speedLimitView.signStandard = routeProgress.currentLegProgress.currentStep.speedLimitSignStandard
            speedLimitView.speedLimit = routeProgress.currentLegProgress.currentSpeedLimit
            speedLimitView.currentSpeed = location.speed
        }
        
        if legIndex != currentLegIndexMapped {
            navigationMapView?.showWaypoints(on: routeProgress.route, legIndex: legIndex)
        }
        
        if annotatesIntersectionsAlongRoute {
            navigationMapView?.updateIntersectionAnnotations(with: routeProgress)
        }
        
        navigationMapView?.updateRouteLine(routeProgress: routeProgress, coordinate: location.coordinate, shouldRedraw: legIndex != currentLegIndexMapped)
        currentLegIndexMapped = legIndex
        
    }
    
    private func checkTunnelState(at location: CLLocation, along progress: RouteProgress) {
        let inTunnel = navigationService.isInTunnel(at: location, along: progress)
        
        // Entering tunnel
        if !isTraversingTunnel, inTunnel {
            isTraversingTunnel = true
            
            if usesNightStyleWhileInTunnel,
               styleManager?.currentStyle?.styleType != .night {
                styleManager?.applyStyle(type: .night)
            }
        }
        
        // Exiting tunnel
        if isTraversingTunnel, !inTunnel {
            isTraversingTunnel = false
            styleManager?.timeOfDayChanged()
            
            if #available(iOS 13.0, *) {
                applyStyleIfNeeded(sessionConfiguration.contentStyle)
            }
        }
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateRouteOnMap()
    }
    
    @objc func refresh(_ notification: NSNotification) {
        navigationMapView?.updateRouteLine(routeProgress: navigationService.routeProgress,
                                           coordinate: navigationService.router.location?.coordinate,
                                           shouldRedraw: true)
    }
    
    @objc func simulationStateDidChange(_ notification: NSNotification) {
        guard let simulationState = notification.userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState,
              let simulatedSpeedMultiplier = notification.userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulatedSpeedMultiplierKey] as? Double
              else { return }

        switch simulationState {
        case .willBeginSimulation:
            navigationMapView?.storeLocationProviderBeforeSimulation()
        case .didBeginSimulation:
            setUpSimulatedLocationProvider(routeProgress: navigationService.routeProgress, speedMultiplier: simulatedSpeedMultiplier)
        case .inSimulation:
            if let simulatesLocation = navigationMapView?.simulatesLocation, !simulatesLocation {
                navigationMapView?.storeLocationProviderBeforeSimulation()
            }
            setUpSimulatedLocationProvider(routeProgress: navigationService.routeProgress, speedMultiplier: simulatedSpeedMultiplier)
        case .willEndSimulation:
            navigationMapView?.useStoredLocationProvider()
        case .didEndSimulation: break
        case .notInSimulation:
            if let simulatesLocation = navigationMapView?.simulatesLocation, simulatesLocation {
                navigationMapView?.useStoredLocationProvider()
            }
        }
    }
    
    @objc func didUpdateRoadNameFromStatus(_ notification: Notification) {
        let roadNameFromStatus = notification.userInfo?[RouteController.NotificationUserInfoKey.roadNameKey] as? String
        if let roadName = roadNameFromStatus?.nonEmptyString {
            let representation = notification.userInfo?[RouteController.NotificationUserInfoKey.routeShieldRepresentationKey] as? VisualInstruction.Component.ImageRepresentation
            wayNameView.label.updateRoad(roadName: roadName, representation: representation, idiom: .carPlay)
            wayNameView.containerView.isHidden = false
        } else {
            wayNameView.text = nil
            wayNameView.containerView.isHidden = true
        }
    }
    
    func setUpSimulatedLocationProvider(routeProgress: RouteProgress, speedMultiplier: Double) {
        let simulatedLocationManager = SimulatedLocationManager(routeProgress: routeProgress)
        simulatedLocationManager.speedMultiplier = speedMultiplier
        navigationMapView?.mapView.location.overrideLocationProvider(with: NavigationLocationProvider(locationManager: simulatedLocationManager))
    }
    
    func updateRouteOnMap() {
        let progress = navigationService.routeProgress
        let legIndex = progress.legIndex
        let nextStep = progress.currentLegProgress.stepIndex + 1
        
        navigationMapView?.updateRouteLine(routeProgress: progress,
                                           coordinate: navigationService.router.location?.coordinate,
                                           shouldRedraw: true)
        if navigationMapView?.routes != nil {
            navigationMapView?.addArrow(route: progress.route, legIndex: legIndex, stepIndex: nextStep)
        } else {
            navigationMapView?.removeArrow()
        }
        navigationMapView?.showWaypoints(on: progress.route, legIndex: legIndex)
        
        if annotatesIntersectionsAlongRoute {
            navigationMapView?.updateIntersectionAnnotations(with: progress)
        }
    }
    
    func updateManeuvers(_ routeProgress: RouteProgress) {
        guard let visualInstruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction else { return }
        let step = navigationService.routeProgress.currentLegProgress.currentStep
        let primaryManeuver = CPManeuver()
        let distance = Measurement(distance: step.distance).localized()
        primaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: distance, timeRemaining: step.expectedTravelTime)
        
        // Just incase, set some default text
        var text = visualInstruction.primaryInstruction.text ?? step.instructions
        if let secondaryText = visualInstruction.secondaryInstruction?.text {
            text += "\n\(secondaryText)"
        }
        primaryManeuver.instructionVariants = [text]
        
        // Add maneuver arrow
        if #available(iOS 13.0, *) {
            let userInterfaceStyle = traitCollection.userInterfaceStyle
            primaryManeuver.symbolImage = visualInstruction.primaryInstruction.maneuverImage(side: visualInstruction.drivingSide,
                                                                                             userInterfaceStyle: userInterfaceStyle)
        } else {
            primaryManeuver.symbolSet = visualInstruction.primaryInstruction.maneuverImageSet(side: visualInstruction.drivingSide)
        }
        
        let junctionImage = guidanceViewManeuverRepresentation(for: visualInstruction,
                                                               navigationService: navigationService)
        primaryManeuver.junctionImage = junctionImage
        
        // Estimating the width of Apple's maneuver view
        let bounds: () -> (CGRect) = {
            let widthOfManeuverView = min(self.view.bounds.width - self.view.safeArea.left,
                                          self.view.bounds.width - self.view.safeArea.right)
            return CGRect(x: 0, y: 0, width: widthOfManeuverView, height: 30)
        }
        
        // Over a certain height, CarPlay devices downsize the image and CarPlay simulators hide the image.
        let shieldHeight: CGFloat = 16
        let maximumImageSize = CGSize(width: .infinity, height: shieldHeight)
        let imageRendererFormat = UIGraphicsImageRendererFormat(for: UITraitCollection(userInterfaceIdiom: .carPlay))
        if let window = carPlayManager.carWindow {
            imageRendererFormat.scale = window.screen.scale
        }
        
        // Regardless of the user interface style that was set in CarPlay settings, whenever user
        // is driving through the tunnel - switch to dark user interface style.
        var traitCollection: UITraitCollection? = nil
        if usesNightStyleWhileInTunnel,
           isTraversingTunnel {
            traitCollection = UITraitCollection.init(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .carPlay),
                UITraitCollection(userInterfaceStyle: .dark)
            ])
        }
        
        if let attributedPrimary = visualInstruction.primaryInstruction.carPlayManeuverLabelAttributedText(bounds: bounds,
                                                                                                           shieldHeight: shieldHeight,
                                                                                                           window: carPlayManager.carWindow,
                                                                                                           traitCollection: traitCollection,
                                                                                                           instructionLabelType: PrimaryLabel.self) {
            
            let instruction = NSMutableAttributedString(attributedString: attributedPrimary)
            
            if let attributedSecondary = visualInstruction.secondaryInstruction?.carPlayManeuverLabelAttributedText(bounds: bounds,
                                                                                                                    shieldHeight: shieldHeight,
                                                                                                                    window: carPlayManager.carWindow,
                                                                                                                    traitCollection: traitCollection,
                                                                                                                    instructionLabelType: SecondaryLabel.self) {
                instruction.append(NSAttributedString(string: "\n"))
                instruction.append(attributedSecondary)
            }
            
            instruction.canonicalizeAttachments(maximumImageSize: maximumImageSize, imageRendererFormat: imageRendererFormat)
            primaryManeuver.attributedInstructionVariants = [instruction]
        }
        
        var maneuvers: [CPManeuver] = [primaryManeuver]
        
        // Add tertiary information, if available
        if let tertiaryInstruction = visualInstruction.tertiaryInstruction {
            let tertiaryManeuver = CPManeuver()
            if tertiaryInstruction.containsLaneIndications {
                // add lanes visual banner
                if let imageSet = visualInstruction.tertiaryInstruction?.lanesImageSet(side: visualInstruction.drivingSide,
                                                                                       direction: visualInstruction.primaryInstruction.maneuverDirection,
                                                                                       scale: (carPlayManager.carWindow?.screen ?? UIScreen.main).scale) {
                    tertiaryManeuver.symbolSet = imageSet
                }

                tertiaryManeuver.userInfo = tertiaryInstruction
            } else {
                // add tertiary maneuver text
                tertiaryManeuver.symbolSet = tertiaryInstruction.maneuverImageSet(side: visualInstruction.drivingSide)

                if let text = tertiaryInstruction.text {
                    tertiaryManeuver.instructionVariants = [text]
                }
                if let attributedTertiary = tertiaryInstruction.carPlayManeuverLabelAttributedText(bounds: bounds,
                                                                                                   shieldHeight: shieldHeight,
                                                                                                   window: carPlayManager.carWindow,
                                                                                                   traitCollection: traitCollection) {
                    let attributedTertiary = NSMutableAttributedString(attributedString: attributedTertiary)
                    attributedTertiary.canonicalizeAttachments(maximumImageSize: maximumImageSize, imageRendererFormat: imageRendererFormat)
                    tertiaryManeuver.attributedInstructionVariants = [attributedTertiary]
                }
            }

            if let upcomingStep = navigationService.routeProgress.currentLegProgress.upcomingStep {
                let distance = Measurement(distance: upcomingStep.distance).localized()
                tertiaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: distance,
                                                                            timeRemaining: upcomingStep.expectedTravelTime)
            }

            maneuvers.append(tertiaryManeuver)
        }
        
        carSession.upcomingManeuvers = maneuvers
    }
    
    /**
     Returns guidance view image representation if it's present in the current visual instruction.
     Since CarPlay doesn't support asynchronous maneuvers update, in case if guidance view image is
     not present in cache - download guidance image first and after that trigger maneuvers update.
     In case if image is present in cache - update primary maneuver right away.
     */
    func guidanceViewManeuverRepresentation(for visualInstruction: VisualInstructionBanner?,
                                            navigationService: NavigationService) -> UIImage? {
        guard let quaternaryInstruction = visualInstruction?.quaternaryInstruction,
              let guidanceView = quaternaryInstruction.components.first,
              let cacheKey = guidanceView.cacheKey else {
            return nil
        }
        
        if let cachedImage = ImageRepository.shared.cachedImageForKey(cacheKey) {
            return cachedImage
        } else {
            guard case let .guidanceView(guidanceViewImageRepresentation, _) = guidanceView,
                  let guidanceImageURL = guidanceViewImageRepresentation.imageURL,
                  let accessToken = navigationService.credentials.accessToken,
                  let guidanceViewImageURL = URL(string: guidanceImageURL.absoluteString + "&access_token=" + accessToken) else {
                return nil
            }
            
            ImageRepository.shared.imageWithURL(guidanceViewImageURL,
                                                cacheKey: cacheKey) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.updateManeuvers(navigationService.routeProgress)
                }
            }
            
            return nil
        }
    }
    
    func presentWaypointArrivalUI(for waypoint: Waypoint) {
        var title = NSLocalizedString("CARPLAY_ARRIVED",
                                      bundle: .mapboxNavigation,
                                      value: "You have arrived",
                                      comment: "Title on arrival action sheet")
        
        if let name = waypoint.name {
            title = name
        }
        
        let continueTitle = NSLocalizedString("CARPLAY_CONTINUE",
                                              bundle: .mapboxNavigation,
                                              value: "Continue",
                                              comment: "Title on continue button in CarPlay")
        
        let continueAlert = CPAlertAction(title: continueTitle, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.carInterfaceController.dismissTemplate(animated: true)
            self.updateRouteOnMap()
        }
        
        let waypointArrival = CPAlertTemplate(titleVariants: [title], actions: [continueAlert])
        // Template has to be dismissed because only one template may be presented at a time.
        carInterfaceController.dismissTemplate(animated: true)
        carInterfaceController.presentTemplate(waypointArrival, animated: true)
    }
    
    func updateIntersectionsAlongRoute() {
        if annotatesIntersectionsAlongRoute {
            navigationMapView?.updateIntersectionSymbolImages(styleType: styleManager?.currentStyleType)
            navigationMapView?.updateIntersectionAnnotations(with: navigationService.routeProgress)
        } else {
            navigationMapView?.removeIntersectionAnnotations()
        }
    }
}

// MARK: StyleManagerDelegate Methods

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: StyleManagerDelegate {
    
    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = navigationService.router.location {
            return location
        } else if let origin = navigationService.route.shape?.coordinates.first {
            return CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        } else {
            return nil
        }
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let mapboxMapStyle = navigationMapView?.mapView.mapboxMap.style
        let styleURI = StyleURI(url: style.mapStyleURL)
        if mapboxMapStyle?.uri?.rawValue != style.mapStyleURL.absoluteString {
            mapboxMapStyle?.uri = styleURI
        }
        
        wayNameView?.label.updateStyle(styleURI: styleURI, idiom: .carPlay)
        updateMapTemplateStyle()
        updateManeuvers(navigationService.routeProgress)
        updateIntersectionsAlongRoute()
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        guard let mapboxMap = navigationMapView?.mapView.mapboxMap,
              let styleURI = mapboxMap.style.uri else { return }
        
        mapboxMap.loadStyleURI(styleURI) { [weak self] result in
            switch result {
            case .success(_):
                // In case if buildings layer present - update its background color.
                self?.navigationMapView?.updateBuildingsLayerIfPresent()
            case .failure(let error):
                Log.error("Failed to load \(styleURI) with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
    }
}

// MARK: NavigationServiceDelegate Methods

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: NavigationServiceDelegate {
    
    public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        let shouldPresentArrivalUI = delegate?.carPlayNavigationViewController(self, shouldPresentArrivalUIFor: waypoint) ?? true
        
        if service.routeProgress.isFinalLeg && shouldPresentArrivalUI {
            presentArrivalUI()
        } else if shouldPresentArrivalUI {
            presentWaypointArrivalUI(for: waypoint)
        }
        return true
    }
}

// MARK: NavigationMapViewDelegate Methods

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  didAdd finalDestinationAnnotation: PointAnnotation,
                                  pointAnnotationManager: PointAnnotationManager) {
        delegate?.carPlayNavigationViewController(self,
                                                  didAdd: finalDestinationAnnotation,
                                                  pointAnnotationManager: pointAnnotationManager)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  routeLineLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> LineLayer? {
        return delegate?.carPlayNavigationViewController(self,
                                                         routeLineLayerWithIdentifier: identifier,
                                                         sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  routeCasingLineLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> LineLayer? {
        return delegate?.carPlayNavigationViewController(self,
                                                         routeCasingLineLayerWithIdentifier: identifier,
                                                         sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  routeRestrictedAreasLineLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> LineLayer? {
        return delegate?.carPlayNavigationViewController(self,
                                                         routeRestrictedAreasLineLayerWithIdentifier: identifier,
                                                         sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, willAdd layer: Layer) -> Layer? {
        return delegate?.carPlayNavigationViewController(self, willAdd: layer)
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: CPSessionConfigurationDelegate {
    
    @available(iOS 13.0, *)
    public func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                                     contentStyleChanged contentStyle: CPContentStyle) {
        applyStyleIfNeeded(contentStyle)
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: CPListTemplateDelegate {
    
    public func listTemplate(_ listTemplate: CPListTemplate,
                      didSelect item: CPListItem,
                      completionHandler: @escaping () -> Void) {
        // Selected a list item for switching to alternative route.
        guard let userInfo = item.userInfo as? CarPlayUserInfo,
              let alternativeId = userInfo[CarPlayAlternativeIDKey] as? AlternativeRoute.ID,
              let alternativeRoute = continuousAlternatives.first(where: { $0.id == alternativeId})?.indexedRouteResponse else {
                  completionHandler()
                  return
              }
        
        navigationService.router.updateRoute(with: alternativeRoute,
                                             routeOptions: nil,
                                             completion: { _ in
            self.carInterfaceController.popTemplate(animated: true)
            completionHandler()
        })
    }
}

#endif
