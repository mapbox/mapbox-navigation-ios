import CarPlay
import Combine
import Foundation
import MapboxDirections
import MapboxNavigationCore
@_spi(Restricted) import MapboxMaps

let CarPlayAlternativeIDKey: String = "MBCarPlayAlternativeID"

/// ``CarPlayNavigationViewController`` is a fully-featured turn-by-turn navigation UI for CarPlay.
/// - SeeAlso: ``NavigationViewController``
open class CarPlayNavigationViewController: UIViewController {
    // MARK: Child Views and Styling Configuration

    /// A view indicating what direction the vehicle is traveling towards, snapped to eight cardinal directions in steps
    /// of 45°.
    ///
    /// This view is hidden by default.
    public var compassView: CarPlayCompassView!

    /// A view that displays the current speed limit.
    public var speedLimitView: SpeedLimitView!

    /// A view that displays the current road name.
    public var wayNameView: WayNameView!

    /// Session configuration that is used to track `CPContentStyle` related changes.
    var sessionConfiguration: CPSessionConfiguration!

    /// The interface styles available for display.
    ///
    /// These are the styles available to the view controller’s internal ``StyleManager`` object. In CarPlay, ``Style``
    /// objects primarily affect the appearance of the map, not guidance-related overlay views.
    public var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }

    /// Controls whether the main route style layer and its casing disappears as the user location puck travels over it.
    /// Defaults to `false`.
    ///
    /// If `true`, the part of the route that has been traversed will be rendered with full transparency, to give the
    /// illusion of a disappearing route. To customize the color that appears on the  traversed section of a route,
    /// override the `traversedRouteColor` property for the `NavigationMapView.appearance()`.
    public var routeLineTracksTraversal: Bool = false {
        didSet {
            navigationMapView?.routeLineTracksTraversal = routeLineTracksTraversal
        }
    }

    /// Toggles displaying alternative routes.
    ///
    /// If enabled, view will draw actual alternative route lines on the map.
    /// Default value is `true`.
    public var showsContinuousAlternatives: Bool {
        get { navigationMapView?.showsAlternatives ?? true }
        set { navigationMapView?.showsAlternatives = newValue }
    }

    /// A Boolean value that determines whether the map annotates the intersections on current step during active
    /// navigation.
    ///
    /// If `true`, the map would display an icon of a traffic control device on the intersection, such as traffic
    /// signal, stop sign, yield sign, or railroad crossing.
    /// Defaults to `true`.
    public var annotatesIntersectionsAlongRoute: Bool = true {
        didSet {
            navigationMapView?.showsIntersectionAnnotations = annotatesIntersectionsAlongRoute
        }
    }

    /// `AlternativeRoute`s user might take during this trip to reach the destination using another road.
    ///
    /// Array contents are updated automatically duting the trip. Alternative routes may be slower or longer then the
    /// main route.
    public var continuousAlternatives: [AlternativeRoute] {
        navigationRoutes.alternativeRoutes
    }

    private func format(
        value: LocationDistance,
        labels: (decreasing: String, increasing: String, equal: String)
    ) -> String {
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
        continuousAlternatives.forEach { alternative in
            let title = alternative.route.description
            distanceFormatter.measurementFormatter.numberFormatter.negativePrefix = ""
            let distanceDeltaText = distanceFormatter.string(from: alternative.distanceDelta)
            let distanceDelta = format(
                value: alternative.distanceDelta,
                labels: (
                    decreasing: String.localizedStringWithFormat(
                        "SHORTER_ALTERNATIVE".localizedString(
                            value: "%@ shorter",
                            comment: "Alternatives selection note about a shorter route distance in any unit."
                        ),
                        distanceDeltaText
                    ),
                    increasing: String.localizedStringWithFormat(
                        "LONGER_ALTERNATIVE".localizedString(
                            value: "%@ longer",
                            comment: "Alternatives selection note about a longer route distance in any unit."
                        ),
                        distanceDeltaText
                    ),
                    equal: "SAME_DISTANCE".localizedString(
                        value: "Same distance",
                        comment: "Alternatives selection note about equal travel distance."
                    )
                )
            )
            let timeDeltaText = DateComponentsFormatter.travelTimeString(
                alternative.expectedTravelTimeDelta,
                signed: false,
                unitStyle: .full
            )
            let timeDelta = format(
                value: alternative.expectedTravelTimeDelta,
                labels: (
                    decreasing: String.localizedStringWithFormat(
                        "FASTER_ALTERNATIVE".localizedString(
                            value: "%@ faster",
                            comment: "Alternatives selection note about a faster route time interval in any unit."
                        ),
                        timeDeltaText
                    ),
                    increasing: String.localizedStringWithFormat(
                        "SLOWER_ALTERNATIVE".localizedString(
                            value: "%@ slower",
                            comment: "Alternatives selection note about a slower route time interval in any unit."
                        ),
                        timeDeltaText
                    ),
                    equal: "SAME_TIME".localizedString(
                        value: "Same time",
                        comment: "Alternatives selection note about equal travel time."
                    )
                )
            )

            let items: [CPListItem] = [CPListItem(
                text: String.localizedStringWithFormat(
                    "ALTERNATIVE_NOTES".localizedString(
                        value: "%1$@ / %2$@",
                        comment: "Combined alternatives selection notes about duration (first slot position) and distance (second slot position) delta."
                    ),
                    timeDelta,
                    distanceDelta
                ),
                detailText: nil
            )]
            items.forEach { (item: CPListItem) in
                item.userInfo = [CarPlayAlternativeIDKey: alternative.id]
                item.handler = { [weak self] _, completion in
                    guard let self else { completion(); return }
                    handleSelection(alternativeRoute: alternative, completionHandler: completion)
                }
            }
            let section = CPListSection(
                items: items,
                header: title,
                sectionIndexTitle: nil
            )
            variants.append(section)
        }

        let alternativesTitle = "CARPLAY_ALTERNATIVES".localizedString(
            value: "Alternatives",
            comment: "Title for alternatives selection list button"
        )

        let template = CPListTemplate(
            title: alternativesTitle,
            sections: variants
        )

        let alternativesEmptyVariantsSubtitle = "CARPLAY_ALTERNATIVES_EMPTY_SUBTITLE".localizedString(
            value: "No alternative routes found.",
            comment: "Subtitle for the alternative list template empty variants"
        )

        template.emptyViewSubtitleVariants = [alternativesEmptyVariantsSubtitle]

        return template
    }

    /// Controls whether night style will be used whenever traversing through a tunnel. Defaults to `true`.
    public var usesNightStyleWhileInTunnel: Bool = true

    /// Controls the styling of CarPlayNavigationViewController and its components.
    ///
    /// The style can be modified programmatically by using ``StyleManager/applyStyle(type:)``.
    public private(set) var styleManager: StyleManager?

    /// This property is not used.
    @available(*, deprecated, message: "This feature no longer has any effect.")
    public var waypointStyle: WaypointStyle = .annotation

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
        safeTrailingCompassViewConstraint = compassView.trailingAnchor.constraint(
            equalTo: view.safeTrailingAnchor,
            constant: -8
        )
        trailingCompassViewConstraint = compassView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor,
            constant: -8
        )
        self.compassView = compassView

        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)

        speedLimitView.topAnchor.constraint(equalTo: compassView.bottomAnchor, constant: 8).isActive = true
        safeTrailingSpeedLimitViewConstraint = speedLimitView.trailingAnchor.constraint(
            equalTo: view.safeTrailingAnchor,
            constant: -8
        )
        trailingSpeedLimitViewConstraint = speedLimitView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor,
            constant: -8
        )
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
            wayNameView.heightAnchor.constraint(equalToConstant: 30.0),
        ])

        self.wayNameView = wayNameView
    }

    func setupStyleManager() {
        styleManager = StyleManager(traitCollection: UITraitCollection(userInterfaceIdiom: .carPlay))
        styleManager?.delegate = self
        styleManager?.styles = styles
    }

    /// Updates `CPMapTemplate.tripEstimateStyle` and `CPMapTemplate.guidanceBackgroundColor`.
    func updateMapTemplateStyle() {
        var currentUserInterfaceStyle = traitCollection.userInterfaceStyle
//         Regardless of the user interface style that was set in CarPlay settings style that is
//         currently used in `StyleManager` will have precedence. Precedence of the style over
//         trait collection is required for custom cases (e.g. when user is driving through the tunnel).
        if usesNightStyleWhileInTunnel,
           isTraversingTunnel,
           let styleType = styleManager?.currentStyleType
        {
            switch styleType {
            case .day:
                currentUserInterfaceStyle = .light
            case .night:
                currentUserInterfaceStyle = .dark
            }
        }

        let backgroundColor = delegate?.carPlayNavigationViewController(
            self,
            guidanceBackgroundColorFor: currentUserInterfaceStyle
        )
        switch currentUserInterfaceStyle {
        case .dark:
            mapTemplate.guidanceBackgroundColor = backgroundColor ?? .black
            mapTemplate.tripEstimateStyle = .dark
        default:
            mapTemplate.guidanceBackgroundColor = backgroundColor ?? .white
            mapTemplate.tripEstimateStyle = .light
        }
    }

    // MARK: Collecting User Feedback

    /// Provides methods for creating and sending user feedback.
    public var eventsManager: NavigationEventsManager {
        core.eventsManager()
    }

    var carFeedbackTemplate: CPGridTemplate!

    /// Shows the interface for providing feedback about the route.
    public func showFeedback() {
        carInterfaceController.pushTemplate(carFeedbackTemplate, animated: true, completion: nil)
    }

    func createFeedbackUI() -> CPGridTemplate {
        let feedbackItems: [FeedbackItem] = [
            ActiveNavigationFeedbackType.falsePositiveTraffic,
            ActiveNavigationFeedbackType.falseNegativeTraffic,
            ActiveNavigationFeedbackType.missingConstruction,
            ActiveNavigationFeedbackType.closure,
            ActiveNavigationFeedbackType.wrongSpeedLimit,
            ActiveNavigationFeedbackType.missingSpeedLimit,
        ].map { $0.generateFeedbackItem() }

        let feedbackButtonHandler: (_: CPGridButton) -> Void = { [weak self] button in
            Task { @MainActor in
                guard let self else { return }
                self.carInterfaceController.safePopTemplate(animated: true)

                guard let feedback = await self.eventsManager.createFeedback() else { return }
                let foundItem = feedbackItems.filter { $0.image == button.image }
                guard let feedbackItem = foundItem.first else { return }
                self.eventsManager.sendFeedback(feedback, type: feedbackItem.type)

                let dismissTitle = "CARPLAY_DISMISS".localizedString(
                    value: "Dismiss",
                    comment: "Title for dismiss button"
                )

                let submittedTitle = "CARPLAY_SUBMITTED_FEEDBACK".localizedString(
                    value: "Submitted",
                    comment: "Alert title that shows when feedback has been submitted"
                )

                let action = CPAlertAction(
                    title: dismissTitle,
                    style: .default,
                    handler: { _ in }
                )

                let alert = CPNavigationAlert(
                    titleVariants: [submittedTitle],
                    subtitleVariants: nil,
                    image: nil,
                    primaryAction: action,
                    secondaryAction: nil,
                    duration: 2.5
                )

                self.mapTemplate.present(navigationAlert: alert, animated: true)
            }
        }

        let buttons: [CPGridButton] = feedbackItems.map {
            return CPGridButton(
                titleVariants: [$0.title.components(separatedBy: "\n").joined(separator: " ")],
                image: $0.image,
                handler: feedbackButtonHandler
            )
        }

        let gridTitle = "CARPLAY_FEEDBACK".localizedString(
            value: "Feedback",
            comment: "Title for feedback template in CarPlay"
        )

        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }

    func endOfRouteFeedbackTemplate() -> CPGridTemplate {
        let buttonHandler: (_: CPGridButton) -> Void = { [weak self] button in
            guard let self else { return }

            if button.titleVariants.first != nil {
                core.tripSession().startFreeDrive()
            }

            carInterfaceController.safePopTemplate(animated: true)
            exitNavigation()
        }

        var buttons: [CPGridButton] = []
        let starImage = UIImage(
            named: "star",
            in: .mapboxNavigation,
            compatibleWith: nil
        )!

        let ratingTitle = "RATING_STARS_FORMAT".localizedString(
            value: "%ld star(s) set.",
            comment: "Format for accessibility value of label indicating the existing rating; 1 = number of stars"
        )
        for rating in 1...5 {
            let titleVariant = String.localizedStringWithFormat(ratingTitle, rating)
            let button = CPGridButton(
                titleVariants: [titleVariant],
                image: starImage,
                handler: buttonHandler
            )
            buttons.append(button)
        }

        let gridTitle = "CARPLAY_RATE_RIDE".localizedString(
            value: "Rate your ride",
            comment: "Title for rating template in CarPlay"
        )

        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }

    func presentArrivalUI() {
        let arrivalTitle = "CARPLAY_ARRIVED".localizedString(
            value: "You have arrived",
            comment: "Title on arrival action sheet"
        )

        let arrivalMessage = "CARPLAY_ARRIVED_MESSAGE".localizedString(
            value: "What would you like to do?",
            comment: "Message on arrival action sheet"
        )

        let exitTitle = "CARPLAY_EXIT_NAVIGATION".localizedString(
            value: "Exit navigation",
            comment: "Title on the exit button in the arrival form"
        )

        let exitAction = CPAlertAction(title: exitTitle, style: .cancel) { _ in
            self.exitNavigation()
            self.dismiss(animated: true)
        }

        let rateTitle = "CARPLAY_RATE_TRIP".localizedString(
            value: "Rate your trip",
            comment: "Title on rate button in CarPlay"
        )

        let rateAction = CPAlertAction(title: rateTitle, style: .default) { _ in
            self.carInterfaceController.pushTemplate(self.endOfRouteFeedbackTemplate(), animated: true, completion: nil)
        }

        let alert = CPActionSheetTemplate(
            title: arrivalTitle,
            message: arrivalMessage,
            actions: [rateAction, exitAction]
        )

        carInterfaceController.dismissTemplate(animated: true, completion: nil)
        carInterfaceController.presentTemplate(alert, animated: true, completion: nil)
    }

    // MARK: Navigating the Route

    /// The view controller’s delegate, that is used by the ``CarPlayManager``.
    ///
    /// Do not overwrite this property and use ``CarPlayManagerDelegate`` methods directly.
    public weak var delegate: CarPlayNavigationViewControllerDelegate?

    /// ``CarPlayManager`` instance, which contains main `UIWindow` content and is used by
    /// ``CarPlayNavigationViewController`` for presentation.
    public var carPlayManager: CarPlayManager

    /// The map view showing the route and the user’s location.
    public fileprivate(set) var navigationMapView: NavigationMapView?

    var carSession: CPNavigationSession!

    /// Begins a navigation session along the given trip.
    ///
    /// - Parameter trip: The trip to begin navigating along.
    public func startNavigationSession(for trip: CPTrip) {
        carSession = mapTemplate.startNavigationSession(for: trip)
    }

    /// Ends the current navigation session.
    ///
    /// - Parameter canceled: A Boolean value indicating whether this method is being called because the user intends to
    /// cancel the trip, as opposed to letting it run to completion.
    public func exitNavigation(byCanceling canceled: Bool = false) {
        carSession.finishTrip()

        delegate?.carPlayNavigationViewControllerWillDismiss(self, byCanceling: canceled)

        dismiss(animated: true) {
            self.delegate?.carPlayNavigationViewControllerDidDismiss(self, byCanceling: canceled)
        }
    }

    private var currentVisualInstruction: VisualInstructionBanner?
    private let core: MapboxNavigation
    private var navigationRoutes: NavigationRoutes
    private let accessToken: String

    /// Creates a new CarPlay navigation view controller for the given route controller and user interface.
    /// - Parameters:
    ///   - accessToken: Holds information about your access token which used to initialize Mapbox Navigation SDK.
    ///   - core: An entry point for interacting with the Mapbox Navigation SDK.
    ///   - mapTemplate: The map template visible during the navigation session.
    ///   - interfaceController: The interface controller for CarPlay.
    ///   - manager: The manager for CarPlay.
    ///   - styles: The interface styles that the view controller’s internal ``StyleManager`` object can select from for
    /// display.
    ///   - navigationRoutes: The object, containing all information of routes that will show.
    /// - Postcondition: Call ``startNavigationSession(for:)`` after initializing this object to begin navigation.
    public required init(
        accessToken: String,
        core: MapboxNavigation,
        mapTemplate: CPMapTemplate,
        interfaceController: CPInterfaceController,
        manager: CarPlayManager,
        styles: [Style]? = nil,
        navigationRoutes: NavigationRoutes
    ) {
        self.accessToken = accessToken
        self.core = core
        self.mapTemplate = mapTemplate
        self.carInterfaceController = interfaceController
        self.carPlayManager = manager
        self.styles = styles ?? [StandardDayStyle(), StandardNightStyle()]
        self.navigationRoutes = navigationRoutes

        super.init(nibName: nil, bundle: nil)
        self.carFeedbackTemplate = createFeedbackUI()

        self.sessionConfiguration = CPSessionConfiguration(delegate: self)
    }

    @available(*, unavailable)
    public required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        suspendNotifications()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupOrnaments()
        setupNavigationMapView()
        setupStyleManager()

        observeNotifications()
        core.tripSession().startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
        carPlayManager.delegate?.carPlayManagerDidBeginNavigation(carPlayManager)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyStyleIfNeeded(sessionConfiguration.contentStyle)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspendNotifications()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateMapTemplateStyle()
            updateManeuvers()
        }
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // Trigger update of view constraints to correctly position views like `SpeedLimitView` and
        // `CarPlayCompassView`.
        view.setNeedsUpdateConstraints()
    }

    func applyStyleIfNeeded(_ contentStyle: CPContentStyle) {
        if contentStyle.contains(.dark) {
            styleManager?.applyStyle(type: .night)
        } else if contentStyle.contains(.light) {
            styleManager?.applyStyle(type: .day)
        }
    }

    override public func updateViewConstraints() {
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

    private var lifetimeSubscriptions: Set<AnyCancellable> = []

    func setupNavigationMapView() {
        let location = core.navigation().locationMatching.map(\.enhancedLocation).eraseToAnyPublisher()
        let routeProgress = core.navigation().routeProgress.map { $0?.routeProgress }.eraseToAnyPublisher()
        let navigationMapView = NavigationMapView(
            location: location,
            routeProgress: routeProgress,
            navigationCameraType: .carPlay
        )
        navigationMapView.delegate = self
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false

        // Reapply runtime styling changes each time the style changes.
        navigationMapView.mapView.mapboxMap.onStyleLoaded.sink { [weak self] _ in
            guard let self else { return }
            self.navigationMapView?.localizeLabels()
            navigationMapView.showsTrafficOnRouteLine = false
        }.store(in: &lifetimeSubscriptions)

        navigationMapView.puckType = .puck3D(.navigationCarPlayDefault)

        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
        navigationMapView.mapView.ornaments.options.logo.visibility = .hidden
        navigationMapView.mapView.ornaments.options.attributionButton.visibility = .hidden

        navigationMapView.navigationCamera.update(cameraState: .following)

        view.insertSubview(navigationMapView, at: 0)
        navigationMapView.pinInSuperview()

        self.navigationMapView = navigationMapView
    }

    // MARK: Notifications Observer Methods

    private var cancellable: Set<AnyCancellable> = []

    func observeNotifications() {
        core.navigation().routeProgress.sink { [weak self] progress in
            self?.progressDidChange(progress?.routeProgress)
        }
        .store(in: &cancellable)

        core.navigation().waypointsArrival
            .removeDuplicates()
            .sink { [weak self] state in
                if let event = state.event as? WaypointArrivalStatus.Events.ToWaypoint {
                    self?.didArrive(at: event.waypoint, isFinal: false)
                } else if let event = state.event as? WaypointArrivalStatus.Events.ToFinalDestination {
                    self?.didArrive(at: event.destination, isFinal: false)
                }
            }
            .store(in: &cancellable)

        core.tripSession().navigationRoutes
            .sink { [weak self] routes in
                self?.refresh(with: routes)
            }
            .store(in: &cancellable)

        core.navigation().bannerInstructions
            .sink { [weak self] _ in
                self?.updateManeuvers()
            }
            .store(in: &cancellable)

        core.navigation().locationMatching.sink { [weak self] state in
            self?.didUpdateRoadNameFromStatus(state)
        }
        .store(in: &cancellable)
    }

    func suspendNotifications() {
        cancellable.forEach { $0.cancel() }
    }

    func progressDidChange(_ routeProgress: RouteProgress?) {
        guard let routeProgress,
              let location = core.navigation().currentLocationMatching?.enhancedLocation
        else {
            return
        }
        // Check to see if we're in a tunnel.
        checkTunnelState(at: location, along: routeProgress)

        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }

        let routeDistance = Measurement(distance: routeProgress.distanceRemaining).localized()
        let routeEstimates = CPTravelEstimates(
            distanceRemaining: routeDistance,
            timeRemaining: routeProgress.durationRemaining
        )
        mapTemplate.update(routeEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)

        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let stepDistance = Measurement(distance: stepProgress.distanceRemaining).localized()
        let stepEstimates = CPTravelEstimates(
            distanceRemaining: stepDistance,
            timeRemaining: stepProgress.durationRemaining
        )
        carSession.updateEstimates(stepEstimates, for: maneuver)

        if let compassView, !compassView.isHidden {
            compassView.course = location.course
        }

        if let speedLimitView {
            speedLimitView.signStandard = routeProgress.currentLegProgress.currentStep.speedLimitSignStandard
            speedLimitView.speedLimit = routeProgress.currentLegProgress.currentSpeedLimit
            speedLimitView.currentSpeed = location.speed
        }
    }

    var tunnelAuthority: TunnelAuthority = .liveValue

    private func checkTunnelState(at location: CLLocation, along progress: RouteProgress) {
        let inTunnel = tunnelAuthority.isInTunnel(location, progress)

//         Entering tunnel
        if !isTraversingTunnel, inTunnel {
            isTraversingTunnel = true

            if usesNightStyleWhileInTunnel,
               styleManager?.currentStyle?.styleType != .night
            {
                styleManager?.applyStyle(type: .night)
            }
        }

        // Exiting tunnel
        if isTraversingTunnel, !inTunnel {
            isTraversingTunnel = false
            styleManager?.timeOfDayChanged()

            applyStyleIfNeeded(sessionConfiguration.contentStyle)
        }
    }

    func didArrive(at waypoint: Waypoint, isFinal: Bool) {
        let shouldPresentArrivalUI = delegate?.carPlayNavigationViewController(
            self,
            shouldPresentArrivalUIFor: waypoint
        ) ?? true

        if isFinal, shouldPresentArrivalUI {
            presentArrivalUI()
        } else if shouldPresentArrivalUI {
            presentWaypointArrivalUI(for: waypoint)
        }
    }

    func refresh(with routes: NavigationRoutes?) {
        if let routes {
            navigationRoutes = routes
            navigationMapView?.show(routes, routeAnnotationKinds: [])
        } else {
            navigationMapView?.removeRoutes()
        }
    }

    func didUpdateRoadNameFromStatus(_ state: MapMatchingState) {
        let roadNameFromStatus = state.roadName?.text

        if let roadName = roadNameFromStatus?.nonEmptyString {
            wayNameView.label.updateRoad(
                roadName: roadName,
                representation: state.roadName?.routeShieldRepresentation,
                idiom: .carPlay
            )
            wayNameView.containerView.isHidden = false
        } else {
            wayNameView.text = nil
            wayNameView.containerView.isHidden = true
        }
    }

    func updateManeuvers() {
        guard let routeProgress = core.navigation().currentRouteProgress?.routeProgress,
              let visualInstruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction,
              visualInstruction != currentVisualInstruction
        else { return }
        currentVisualInstruction = visualInstruction
        let step = routeProgress.currentLegProgress.currentStep
        let primaryManeuver = CPManeuver()
        let distance = Measurement(distance: step.distance).localized()
        primaryManeuver.initialTravelEstimates = CPTravelEstimates(
            distanceRemaining: distance,
            timeRemaining: step.expectedTravelTime
        )

        if #available(iOS 15.4, *) {
            primaryManeuver.cardBackgroundColor = #colorLiteral(red: 0.07450980392, green: 0.3137254902, blue: 0.7843137255, alpha: 1)
        }
        // Just incase, set some default text
        var text = visualInstruction.primaryInstruction.text ?? step.instructions
        if let secondaryText = visualInstruction.secondaryInstruction?.text {
            text += "\n\(secondaryText)"
        }
        primaryManeuver.instructionVariants = [text]

        // Add maneuver arrow
        primaryManeuver.symbolSet = visualInstruction.primaryInstruction.maneuverImageSet(
            side: visualInstruction.drivingSide,
            visualInstruction: visualInstruction.primaryInstruction
        )

        let junctionImage = guidanceViewManeuverRepresentation(for: visualInstruction)
        primaryManeuver.junctionImage = junctionImage

        // Estimating the width of Apple's maneuver view
        let bounds: () -> (CGRect) = {
            let widthOfManeuverView = min(
                self.view.bounds.width - self.view.safeArea.left,
                self.view.bounds.width - self.view.safeArea.right
            )
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
           isTraversingTunnel
        {
            traitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .carPlay),
                UITraitCollection(userInterfaceStyle: .dark),
            ])
        }

        if let attributedPrimary = visualInstruction.primaryInstruction.carPlayManeuverLabelAttributedText(
            bounds: bounds,
            shieldHeight: shieldHeight,
            window: carPlayManager.carWindow,
            traitCollection: traitCollection,
            instructionLabelType: PrimaryLabel.self
        ) {
            let instruction = NSMutableAttributedString(attributedString: attributedPrimary)

            if let attributedSecondary = visualInstruction.secondaryInstruction?.carPlayManeuverLabelAttributedText(
                bounds: bounds,
                shieldHeight: shieldHeight,
                window: carPlayManager.carWindow,
                traitCollection: traitCollection,
                instructionLabelType: SecondaryLabel.self
            ) {
                instruction.append(NSAttributedString(string: "\n"))
                instruction.append(attributedSecondary)
            }

            instruction.canonicalizeAttachments(
                maximumImageSize: maximumImageSize,
                imageRendererFormat: imageRendererFormat
            )
            primaryManeuver.attributedInstructionVariants = [instruction]
        }

        var maneuvers: [CPManeuver] = [primaryManeuver]

        // Add tertiary information, if available
        if let tertiaryInstruction = visualInstruction.tertiaryInstruction {
            let tertiaryManeuver = CPManeuver()
            if tertiaryInstruction.containsLaneIndications {
                // add lanes visual banner
                if let imageSet = visualInstruction.tertiaryInstruction?.lanesImageSet(
                    side: visualInstruction.drivingSide,
                    direction: visualInstruction.primaryInstruction.maneuverDirection,
                    scale: (carPlayManager.carWindow?.screen ?? UIScreen.main).scale
                ) {
                    tertiaryManeuver.symbolSet = imageSet
                }

                tertiaryManeuver.userInfo = tertiaryInstruction
            } else {
                // add tertiary maneuver text
                tertiaryManeuver.symbolSet = tertiaryInstruction.maneuverImageSet(side: visualInstruction.drivingSide)

                if let text = tertiaryInstruction.text {
                    tertiaryManeuver.instructionVariants = [text]
                }
                if let attributedTertiary = tertiaryInstruction.carPlayManeuverLabelAttributedText(
                    bounds: bounds,
                    shieldHeight: shieldHeight,
                    window: carPlayManager
                        .carWindow,
                    traitCollection: traitCollection
                ) {
                    let attributedTertiary = NSMutableAttributedString(attributedString: attributedTertiary)
                    attributedTertiary.canonicalizeAttachments(
                        maximumImageSize: maximumImageSize,
                        imageRendererFormat: imageRendererFormat
                    )
                    tertiaryManeuver.attributedInstructionVariants = [attributedTertiary]
                }
            }

            if let upcomingStep = routeProgress.currentLegProgress.upcomingStep {
                let distance = Measurement(distance: upcomingStep.distance).localized()
                tertiaryManeuver.initialTravelEstimates = CPTravelEstimates(
                    distanceRemaining: distance,
                    timeRemaining: upcomingStep
                        .expectedTravelTime
                )
            }

            maneuvers.append(tertiaryManeuver)
        }

        carSession.upcomingManeuvers = maneuvers
    }

    /// Returns guidance view image representation if it's present in the current visual instruction.
    /// Since CarPlay doesn't support asynchronous maneuvers update, in case if guidance view image is not present in
    /// cache - download guidance image first and after that trigger maneuvers update.
    ///
    /// In case if image is present in cache - update primary maneuver right away.
    func guidanceViewManeuverRepresentation(for visualInstruction: VisualInstructionBanner?) -> UIImage? {
        guard let quaternaryInstruction = visualInstruction?.quaternaryInstruction,
              let guidanceView = quaternaryInstruction.components.first,
              let cacheKey = guidanceView.cacheKey
        else {
            return nil
        }

        if let cachedImage = ImageRepository.shared.cachedImageForKey(cacheKey) {
            return cachedImage
        } else {
            guard case .guidanceView(let guidanceViewImageRepresentation, _) = guidanceView,
                  let guidanceImageURL = guidanceViewImageRepresentation.imageURL,
                  let guidanceViewImageURL = URL(
                      string: guidanceImageURL
                          .absoluteString + "&access_token=" + accessToken
                  )
            else {
                return nil
            }

            ImageRepository.shared.imageWithURL(
                guidanceViewImageURL,
                cacheKey: cacheKey
            ) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.updateManeuvers()
                }
            }

            return nil
        }
    }

    func presentWaypointArrivalUI(for waypoint: Waypoint) {
        var title = "CARPLAY_ARRIVED".localizedString(
            value: "You have arrived",
            comment: "Title on arrival action sheet"
        )

        if let name = waypoint.name {
            title = name
        }

        let continueTitle = "CARPLAY_CONTINUE".localizedString(
            value: "Continue",
            comment: "Title on continue button in CarPlay"
        )

        let continueAlert = CPAlertAction(title: continueTitle, style: .default) { [weak self] _ in
            guard let self else { return }
            carInterfaceController.dismissTemplate(animated: true, completion: nil)
        }

        let waypointArrival = CPAlertTemplate(titleVariants: [title], actions: [continueAlert])
        // Template has to be dismissed because only one template may be presented at a time.
        carInterfaceController.dismissTemplate(animated: true, completion: nil)
        carInterfaceController.presentTemplate(waypointArrival, animated: true, completion: nil)
    }
}

// MARK: StyleManagerDelegate Methods

extension CarPlayNavigationViewController: StyleManagerDelegate {
    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = core.navigation().currentLocationMatching?.enhancedLocation {
            return location
        } else {
            return nil
        }
    }

    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let styleURI = StyleURI(url: style.mapStyleURL)
        if let navigationMapView {
            style.applyMapStyle(to: navigationMapView)
        }

        wayNameView?.label.updateStyle(styleURI: styleURI, idiom: .carPlay)
        updateMapTemplateStyle()
        updateManeuvers()
    }

    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        guard let mapboxMap = navigationMapView?.mapView.mapboxMap,
              let styleURI = mapboxMap.styleURI else { return }

        mapboxMap.loadStyle(styleURI, transition: nil) { error in
            if let error {
                Log.error(
                    "Failed to load \(styleURI) with error: \(error.localizedDescription).",
                    category: .navigationUI
                )
            }
        }
    }
}

// MARK: NavigationMapViewDelegate Methods

extension CarPlayNavigationViewController: NavigationMapViewDelegate {
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        delegate?.carPlayNavigationViewController(
            self,
            waypointCircleLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        delegate?.carPlayNavigationViewController(
            self,
            waypointSymbolLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        delegate?.carPlayNavigationViewController(
            self,
            shapeFor: waypoints,
            legIndex: legIndex
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayNavigationViewController(
            self,
            routeLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayNavigationViewController(
            self,
            routeCasingLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayNavigationViewController(
            self,
            routeRestrictedAreasLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(_ navigationMapView: NavigationMapView, willAdd layer: Layer) -> Layer? {
        delegate?.carPlayNavigationViewController(self, willAdd: layer)
    }
}

extension CarPlayNavigationViewController: CPSessionConfigurationDelegate {
    public func sessionConfiguration(
        _ sessionConfiguration: CPSessionConfiguration,
        contentStyleChanged contentStyle: CPContentStyle
    ) {
        applyStyleIfNeeded(contentStyle)
    }
}

extension CarPlayNavigationViewController {
    func handleSelection(
        alternativeRoute: AlternativeRoute,
        completionHandler: @escaping () -> Void
    ) {
        // Selected a list item for switching to alternative route.
        Task { @MainActor in
            if let routes = await navigationRoutes.selecting(alternativeRoute: alternativeRoute) {
                self.navigationRoutes = routes
                let startLegIndex = core.navigation().currentRouteProgress?.routeProgress.legIndex ?? 0
                core.tripSession().startActiveGuidance(with: routes, startLegIndex: startLegIndex)

                navigationMapView?.show(routes, routeAnnotationKinds: [])
                try await self.carInterfaceController.popTemplate(animated: true)
            }
            completionHandler()
        }
    }
}
