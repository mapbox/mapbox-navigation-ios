import CarPlay
import Combine
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore

/// ``CarPlayManager`` is the main object responsible for orchestrating interactions with a Mapbox map on CarPlay.
/// Messages declared in the `CPTemplateApplicationSceneDelegate` protocol should be sent to this object in the
/// containing
/// application's application delegate. Implement ``CarPlayManagerDelegate`` in the containing application and assign an
/// instance to the ``delegate`` property of your ``CarPlayManager`` instance.
///  - Note: It is very important you have a single ``CarPlayManager`` instance at any given time.
///  - Important: ``CarPlayManager`` view will start a Free Drive session by default when CarPlay interface is
/// connected. You can change default behavior using ``CarPlayManager/startFreeDriveAutomatically`` property. For more
/// information, see the “[Pricing](https://docs.mapbox.com/ios/navigation/guides/pricing/)” guide.
public class CarPlayManager: NSObject {
    // MARK: CarPlay Infrastructure

    /// A controller that manages the templates for constructing a scene’s user interface.
    public fileprivate(set) var interfaceController: CPInterfaceController?

    /// Main window for content, presented on the CarPlay screen.
    public fileprivate(set) var carWindow: UIWindow?

    /// A template that displays a navigation overlay on the map.
    public fileprivate(set) var mainMapTemplate: CPMapTemplate?

    /// A Boolean value indicating whether the phone is connected to CarPlay.
    public static var isConnected = false

    // MARK: Navigation Configuration

    /// Controls whether ``CarPlayManager`` starts a Free Drive session automatically on map load.
    ///
    /// If you set this property to false, you can start a Free Drive session using
    /// ``CarPlayMapViewController/startFreeDriveNavigation()`` method. For example:
    /// ```
    /// carPlayManager.carPlayMapViewController?.startFreeDriveNavigation()
    /// ```
    public var startFreeDriveAutomatically: Bool = true

    /// Developers should assign their own object as a delegate implementing the ``CarPlayManagerDelegate`` protocol for
    /// customization.
    public weak var delegate: CarPlayManagerDelegate?

    /// `UIViewController`, which provides a fully-featured turn-by-turn navigation UI for CarPlay.
    public fileprivate(set) weak var carPlayNavigationViewController: CarPlayNavigationViewController?

    /// Property, which contains type of ``CarPlayNavigationViewController``.
    public let carPlayNavigationViewControllerType: CarPlayNavigationViewController.Type

    /// The events manager used during turn-by-turn navigation while connected to CarPlay.
    public let eventsManager: NavigationEventsManager

    /// Returns current ``CarPlayActivity``, which is based on currently present `CPTemplate`. In case if `CPTemplate`
    /// was
    /// not created by ``CarPlayManager`` `currentActivity` will be assigned to `nil`.
    public private(set) var currentActivity: CarPlayActivity?
    private var idleTimerCancellable: IdleTimerManager.Cancellable?
    private var routes: NavigationRoutes?

    /// Programatically begins a CarPlay turn-by-turn navigation session.
    /// - Parameter currentLocation: The current location of the user. This will be used to initally draw the current
    /// location icon.
    public func beginNavigationWithCarPlay(using currentLocation: CLLocationCoordinate2D) {
        Task { @MainActor in
            if let routes = core.tripSession().currentNavigationRoutes {
                var trip = await CPTrip(routes: routes)
                trip = delegate?.carPlayManager(self, willPreview: trip) ?? trip

                if let mapTemplate = mainMapTemplate, let routeChoice = trip.routeChoices.first {
                    self.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
                }
            }
        }
    }

    private let navigationProvider: MapboxNavigationProvider
    private let core: MapboxNavigation
    private var cameraStateCancellable: AnyCancellable?
    private var fetchedSearchResults: [SearchResultRecord] = []

    /// Initializes a new CarPlay manager that manages a connection to the CarPlay interface.
    /// - Parameters:
    ///   - navigationProvider: The main object of MapboxNavigationCore which is using as a single source of truth for
    /// all logic.
    ///   - styles: The styles to display in the CarPlay interface. If this argument is omitted, ``StandardDayStyle``
    /// and ``StandardNightStyle`` are displayed by default.
    @MainActor
    public convenience init(
        navigationProvider: MapboxNavigationProvider,
        styles: [Style]? = nil
    ) {
        self.init(
            navigationProvider: navigationProvider,
            styles: styles,
            carPlayNavigationViewControllerClass: nil
        )
    }

    @MainActor
    init(
        navigationProvider: MapboxNavigationProvider,
        styles: [Style]? = nil,
        carPlayNavigationViewControllerClass: CarPlayNavigationViewController.Type? = nil
    ) {
        self.navigationProvider = navigationProvider
        self.core = navigationProvider.mapboxNavigation
        self.eventsManager = navigationProvider.mapboxNavigation.eventsManager()
        self.styles = styles ?? [StandardDayStyle(), StandardNightStyle()]
        self.mapTemplateProvider = MapTemplateProvider()
        self
            .carPlayNavigationViewControllerType = carPlayNavigationViewControllerClass ??
            CarPlayNavigationViewController.self

        super.init()

        mapTemplateProvider.delegate = self
    }

    func subscribeForNotifications() {
        Task { @MainActor in
            cameraStateCancellable = navigationMapView?.navigationCamera.cameraStates
                .sink { [weak self] in
                    self?.navigationCameraStateDidChange($0)
                }
        }
    }

    func unsubscribeFromNotifications() {
        cameraStateCancellable?.cancel()
    }

    @MainActor
    func navigationCameraStateDidChange(_ state: NavigationCameraState) {
        switch state {
        case .idle:
            carPlayMapViewController?.recenterButton.isHidden = false
        case .following:
            carPlayMapViewController?.recenterButton.isHidden = true
        case .overview:
            break
        }

        let traitCollection: UITraitCollection
        if let carPlayNavigationViewController {
            traitCollection = carPlayNavigationViewController.traitCollection
        } else if let carPlayMapViewController {
            traitCollection = carPlayMapViewController.traitCollection
        } else {
            assertionFailure("Panning interface is only supported for free-drive or active-guidance navigation.")
            return
        }

        guard let mapTemplate = interfaceController?.rootTemplate as? CPMapTemplate,
              let activity = mapTemplate.currentActivity
        else {
            return
        }

        if let buttons = delegate?.carPlayManager(
            self,
            leadingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: activity,
            cameraState: state
        ) {
            mapTemplate.leadingNavigationBarButtons = buttons
        }
    }

    // MARK: Map Configuration

    /// The styles displayed in the CarPlay interface.
    @MainActor
    public var styles: [Style] {
        didSet {
            carPlayMapViewController?.styles = styles
            carPlayNavigationViewController?.styles = styles
        }
    }

    /// The view controller for orchestrating the Mapbox map, the interface styles and the map template buttons on
    /// CarPlay.
    @MainActor
    public var carPlayMapViewController: CarPlayMapViewController? {
        if let carPlayMapViewController = carWindow?.rootViewController as? CarPlayMapViewController {
            return carPlayMapViewController
        }
        return nil
    }

    /// The main `NavigationMapView` displayed inside CarPlay.
    @MainActor
    public var navigationMapView: NavigationMapView? {
        return carPlayMapViewController?.navigationMapView
    }

    @MainActor
    var activeNavigationMapView: NavigationMapView? {
        if let carPlayNavigationViewController,
           let validNavigationMapView = carPlayNavigationViewController.navigationMapView
        {
            return validNavigationMapView
        } else if let carPlayMapViewController {
            return carPlayMapViewController.navigationMapView
        } else {
            return nil
        }
    }

    var mapTemplateProvider: MapTemplateProvider

    // MARK: Customizing the Bar Buttons

    /// The bar button that exits the navigation session.
    public lazy var exitButton: CPBarButton = {
        let title = "CARPLAY_END".localizedString(value: "End", comment: "Title for end navigation button")

        let exitButton = CPBarButton(title: title) { [weak self] (_: CPBarButton) in
            self?.carPlayNavigationViewController?.exitNavigation(byCanceling: true)
        }

        return exitButton
    }()

    /// The bar button that mutes the voice turn-by-turn instruction announcements during navigation.
    @MainActor
    public lazy var muteButton: CPBarButton = {
        let muteTitle = "CARPLAY_MUTE".localizedString(value: "Mute", comment: "Title for mute button")
        let unmuteTitle = "CARPLAY_UNMUTE".localizedString(value: "Unmute", comment: "Title for unmute button")

        let title = isVoiceMuted ? unmuteTitle : muteTitle
        let muteButton = CPBarButton(title: title) { [weak self] (button: CPBarButton) in
            self?.routeVoiceController.speechSynthesizer.muted.toggle()
            button.title = self?.isVoiceMuted == true ? unmuteTitle : muteTitle
        }

        return muteButton
    }()

    @MainActor
    private lazy var routeVoiceController = navigationProvider.routeVoiceController

    @MainActor
    private var isVoiceMuted: Bool {
        return routeVoiceController.speechSynthesizer.muted
    }

    /// The bar button that brings alternative routes selection during navigation.
    public lazy var alternativeRoutesButton: CPBarButton = {
        let title = "CARPLAY_ALTERNATIVES".localizedString(
            value: "Alternatives",
            comment: "Title for alternatives selection list button"
        )

        let altsButton = CPBarButton(title: title) { [weak self] (_: CPBarButton) in
            self?.showAlternativesListTemplate()
        }

        return altsButton
    }()

    @_spi(MapboxInternal)
    public func showAlternativesListTemplate() {
        guard let template = carPlayNavigationViewController?.alternativesListTemplate() else {
            return
        }
        interfaceController?.pushTemplate(
            template,
            animated: true,
            completion: nil
        )
    }

    /// The bar button that prompts the presented navigation view controller to display the feedback screen.
    public lazy var showFeedbackButton: CPMapButton = {
        let showFeedbackButton = CPMapButton { [weak self] _ in
            self?.carPlayNavigationViewController?.showFeedback()
        }

        showFeedbackButton.image = UIImage(
            named: "carplay_feedback",
            in: .mapboxNavigation,
            compatibleWith: nil
        )

        return showFeedbackButton
    }()

    /// The bar button that shows the selected route overview on the map.
    public lazy var userTrackingButton: CPMapButton = {
        let userTrackingButton = CPMapButton { [weak self] _ in
            guard let navigationMapView = self?.carPlayNavigationViewController?.navigationMapView else { return }

            Task { @MainActor in
                if navigationMapView.navigationCamera.currentCameraState == .following {
                    navigationMapView.navigationCamera.update(cameraState: .overview)
                } else {
                    navigationMapView.navigationCamera.update(cameraState: .following)
                }
            }
        }

        userTrackingButton.image = UIImage(
            named: "carplay_overview",
            in: .mapboxNavigation,
            compatibleWith: nil
        )

        return userTrackingButton
    }()
}

// MARK: CPApplicationDelegate Methods

@available(*, deprecated, message: "Use CPTemplateApplicationSceneDelegate methods instead")
extension CarPlayManager: CPApplicationDelegate {
    @MainActor
    public func application(
        _ application: UIApplication,
        didConnectCarInterfaceController interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        handleDidConnect(interfaceController: interfaceController, to: window)
    }

    @MainActor
    public func application(
        _ application: UIApplication,
        didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        handleDidDisconnect(interfaceController: interfaceController, from: window)
    }
}

// MARK: CPTemplateApplicationSceneDelegate Methods

extension CarPlayManager: CPTemplateApplicationSceneDelegate {
    @MainActor
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        handleDidConnect(interfaceController: interfaceController, to: window)
    }

    @MainActor
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        handleDidDisconnect(interfaceController: interfaceController, from: window)
    }
}

// MARK: InterfaceController handling Methods

extension CarPlayManager {
    @MainActor
    func handleDidConnect(interfaceController: CPInterfaceController, to window: CPWindow) {
        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let shouldDisableIdleTimer = delegate?.carPlayManagerShouldDisableIdleTimer(self) ?? true
        if shouldDisableIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }
        let carPlayMapViewController = CarPlayMapViewController(core: core, styles: styles)
        carPlayMapViewController.userInfo = eventsManager.userInfo
        carPlayMapViewController.startFreeDriveAutomatically = startFreeDriveAutomatically
        carPlayMapViewController.delegate = self
        window.rootViewController = carPlayMapViewController
        carWindow = window

        let mapTemplate = previewMapTemplate()
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false, completion: nil)

        eventsManager.sendCarPlayConnectEvent()

        subscribeForNotifications()
    }

    @MainActor
    func handleDidDisconnect(interfaceController: CPInterfaceController, from window: CPWindow) {
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

    @MainActor
    func previewMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let currentActivity: CarPlayActivity = .browsing
        mapTemplate.userInfo = [
            CarPlayManager.currentActivityKey: currentActivity,
        ]

        guard let carPlayMapViewController else { return mapTemplate }

        let traitCollection = carPlayMapViewController.traitCollection

        if let leadingButtons = delegate?.carPlayManager(
            self,
            leadingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: currentActivity
        ) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }

        if let trailingButtons = delegate?.carPlayManager(
            self,
            trailingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: currentActivity
        ) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }

        if let mapButtons = delegate?.carPlayManager(
            self,
            mapButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: currentActivity
        ) {
            mapTemplate.mapButtons = mapButtons
        } else if let mapButtons = browsingMapButtons(for: mapTemplate) {
            mapTemplate.mapButtons = mapButtons
        }

        return mapTemplate
    }

    @MainActor
    public func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        if mapTemplate.isPanningInterfaceVisible,
           let carPlayMapViewController
        {
            if let mapButtons = delegate?.carPlayManager(
                self,
                mapButtonsCompatibleWith: carPlayMapViewController
                    .traitCollection,
                in: mapTemplate,
                for: .browsing
            ) {
                mapTemplate.mapButtons = mapButtons
            } else if let mapButtons = browsingMapButtons(for: mapTemplate) {
                mapTemplate.mapButtons = mapButtons
            }

            mapTemplate.dismissPanningInterface(animated: false)
        }
    }

    @MainActor
    private func browsingMapButtons(for mapTemplate: CPMapTemplate) -> [CPMapButton]? {
        guard let carPlayMapViewController else {
            return nil
        }

        let panMapButton = carPlayMapViewController.panningInterfaceDisplayButton(for: mapTemplate)
        carPlayMapViewController.panMapButton = panMapButton

        let mapButtons = [
            carPlayMapViewController.recenterButton,
            panMapButton,
            carPlayMapViewController.zoomInButton,
            carPlayMapViewController.zoomOutButton,
        ]

        return mapButtons
    }
}

// MARK: CPInterfaceControllerDelegate Methods

extension CarPlayManager: CPInterfaceControllerDelegate {
    public func templateWillAppear(_ template: CPTemplate, animated: Bool) {
        Task { @MainActor in
            delegate?.carPlayManager(self, templateWillAppear: template, animated: animated)

            if template == interfaceController?.rootTemplate,
               let carPlayMapViewController
            {
                carPlayMapViewController.recenterButton.isHidden = true
            }

            if let currentActivity = template.currentActivity {
                self.currentActivity = currentActivity
            } else {
                self.currentActivity = nil
            }
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

    /// Calculates routes to the given destination using the [Mapbox Directions
    /// API](https://www.mapbox.com/api-documentation/navigation/#directions) and previews them on a map.
    ///
    /// Upon successful calculation a new template will be pushed onto the template navigation hierarchy.
    /// - Parameters:
    ///   - destination: A final destination `Waypoint`.
    ///   - completionHandler: A closure to be executed when the calculation completes.
    public func previewRoutes(to destination: Waypoint, completionHandler: @escaping CompletionHandler) {
        Task { @MainActor in
            await previewRoutes(to: destination)
            completionHandler()
        }
    }

    /// Calculates routes to the given destination using the [Mapbox Directions
    /// API](https://www.mapbox.com/api-documentation/navigation/#directions) and previews them on a map.
    ///
    /// Upon successful calculation a new template will be pushed onto the template navigation hierarchy.
    /// - Parameters:
    ///   - destination: A final destination `Waypoint`.
    public func previewRoutes(to destination: Waypoint) async {
        guard let carPlayMapViewController = await carPlayMapViewController,
              let userLocation = await carPlayMapViewController.navigationMapView.mapView.location.latestLocation
        else {
            return
        }

        let name = "CARPLAY_CURRENT_LOCATION".localizedString(
            value: "Current Location",
            comment: "Name of the waypoint associated with the current location"
        )

        let location = CLLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )

        let origin = Waypoint(location: location, name: name)

        await previewRoutes(between: [origin, destination])
    }

    /// Allows to preview routes for a list of `Waypoint` objects.
    /// - Parameters:
    ///   - waypoints: A list of `Waypoint` objects.
    ///   - completionHandler: A closure to be executed when the calculation completes.
    public func previewRoutes(between waypoints: [Waypoint], completionHandler: @escaping CompletionHandler) {
        let options = NavigationRouteOptions(waypoints: waypoints)
        previewRoutes(for: options, completionHandler: completionHandler)
    }

    /// Allows to preview routes for a list of `Waypoint` objects.
    /// - Parameters:
    ///   - waypoints: A list of `Waypoint` objects.
    public func previewRoutes(between waypoints: [Waypoint]) async {
        let options = NavigationRouteOptions(waypoints: waypoints)
        await previewRoutes(for: options)
    }

    /// Calculates routes satisfying the given options using the [Mapbox Directions
    /// API](https://www.mapbox.com/api-documentation/navigation/#directions) and previews them on a map.
    /// - Parameters:
    ///   - options: A `RouteOptions` object, which specifies the criteria for results returned by the Mapbox Directions
    /// API.
    ///   - completionHandler: A closure to be executed when the calculation completes.
    public func previewRoutes(for options: RouteOptions, completionHandler: @escaping CompletionHandler) {
        Task {
            let task = await core.routingProvider().calculateRoutes(options: options)
            await didCalculate(task, for: options)
            completionHandler()
        }
    }

    // Calculates routes satisfying the given options using the [Mapbox Directions
    /// API](https://www.mapbox.com/api-documentation/navigation/#directions) and previews them on a map.
    /// - Parameters:
    ///   - options: A `RouteOptions` object, which specifies the criteria for results returned by the Mapbox Directions
    /// API.
    public func previewRoutes(for options: RouteOptions) async {
        let task = await core.routingProvider().calculateRoutes(options: options)
        await didCalculate(task, for: options)
    }

    /// Allows to preview routes for a specific `NavigationRoutes` object.
    /// - Parameter routes: `NavigationRoutes` object, containing all information of routes that will be previewed.
    public func previewRoutes(for routes: NavigationRoutes) async {
        guard shouldPreviewRoutes(for: routes) else { return }
        let trip = await CPTrip(routes: routes)
        try? await previewRoutes(for: trip)
    }

    /// Allows to cancel routes preview on CarPlay .
    @MainActor
    public func cancelRoutesPreview() async {
        guard routes != nil else { return }
        carPlayMapViewController?.removeSearchResultsAnnotations()
        var configuration = CarPlayManagerCancelPreviewConfiguration()
        delegate?.carPlayManagerWillCancelPreview(self, configuration: &configuration)
        routes = nil
        mainMapTemplate?.hideTripPreviews()
        if configuration.popToRoot {
            _ = try? await popToRootTemplate(interfaceController: interfaceController, animated: true)
        }
        clearMapAnnotations()
        navigationMapView?.navigationCamera.update(cameraState: .following)
        delegate?.carPlayManagerDidCancelPreview(self)
    }

    func shouldPreviewRoutes(for routes: NavigationRoutes) -> Bool {
        guard self.routes?.mainRoute == routes.mainRoute else { return true }
        return self.routes?.alternativeRoutes != routes.alternativeRoutes
    }

    @MainActor
    @_spi(MapboxInternal)
    public func previewRoutes(with searchResults: [SearchResultRecord]) async throws {
        guard let traitCollection = (carWindow?.rootViewController as? CarPlayMapViewController)?.traitCollection,
              let interfaceController
        else {
            return
        }

        let template = mapTemplateProvider.mapTemplate(
            traitCollection: traitCollection,
            mapDelegate: self
        )

        struct DataForPreview {
            let trip: CPTrip
            let estimates: CPTravelEstimates?
        }

        var dataForPreviews: [DataForPreview] = []
        for searchResult in searchResults {
            let trip = CPTrip(searchResultRecord: searchResult)
            var estimates: CPTravelEstimates?
            if let distance = searchResult.estimatedDistance,
               let time = searchResult.estimatedTime
            {
                estimates = CPTravelEstimates(
                    distanceRemaining: .init(distance: distance),
                    timeRemaining: time
                )
            }
            dataForPreviews.append(.init(trip: trip, estimates: estimates))
        }

        let trips = dataForPreviews.map(\.trip)

        template.showTripPreviews(
            trips,
            selectedTrip: trips.first,
            textConfiguration: nil
        )

        for dataForPreview in dataForPreviews {
            guard let estimates = dataForPreview.estimates else { continue }
            template.updateEstimates(estimates, for: dataForPreview.trip)
        }

        fetchedSearchResults = searchResults
        carPlayMapViewController?.showSearchResultsAnnotations(with: searchResults, selectedResult: searchResults.first)
        _ = try? await popToRootTemplate(interfaceController: interfaceController, animated: false)
        try await interfaceController.pushTemplate(template, animated: true)
    }

    @MainActor
    func previewRoutes(for trip: CPTrip) async throws {
        guard let traitCollection = (carWindow?.rootViewController as? CarPlayMapViewController)?.traitCollection,
              let interfaceController
        else {
            return
        }

        let modifiedTrip = delegate?.carPlayManager(self, willPreview: trip) ?? trip

        let previewMapTemplate = mapTemplateProvider.mapTemplate(
            traitCollection: traitCollection,
            mapDelegate: self
        )

        var previewText = defaultTripPreviewTextConfiguration()
        if let customPreviewText = delegate?.carPlayManager(self, willPreview: modifiedTrip, with: previewText) {
            previewText = customPreviewText
        }

        previewMapTemplate.backButton = defaultTripPreviewBackButton()
        previewMapTemplate.showTripPreviews([modifiedTrip], textConfiguration: previewText)

        if currentActivity == .previewing {
            try await interfaceController.popTemplate(animated: false)
            try await interfaceController.pushTemplate(previewMapTemplate, animated: false)
        } else {
            try await interfaceController.pushTemplate(previewMapTemplate, animated: true)
        }
    }

    func removeRoutesFromMap() {
        Task { @MainActor in
            routes = nil
            guard let navigationMapView = carPlayMapViewController?.navigationMapView else { return }
            navigationMapView.removeRoutes()
        }
    }

    func didCalculate(_ task: Task<NavigationRoutes, Error>, for routeOptions: RouteOptions) async {
        do {
            let routes = try await task.value
            await previewRoutes(for: routes)
        } catch {
            guard let delegate, let alert = delegate.carPlayManager(
                self,
                didFailToFetchRouteBetween: routeOptions.waypoints,
                options: routeOptions,
                error: error
            ) else {
                return
            }

            let mapTemplate = interfaceController?.rootTemplate as? CPMapTemplate
            _ = try? await popToRootTemplate(interfaceController: interfaceController, animated: true)
            mapTemplate?.present(navigationAlert: alert, animated: true)
        }
    }

    private func defaultTripPreviewTextConfiguration() -> CPTripPreviewTextConfiguration {
        let goTitle = "CARPLAY_GO".localizedString(
            value: "Go",
            comment: "Title for start button in CPTripPreviewTextConfiguration"
        )

        let alternativeRoutesTitle = "CARPLAY_MORE_ROUTES".localizedString(
            value: "More Routes",
            comment: "Title for alternative routes in CPTripPreviewTextConfiguration"
        )

        let overviewTitle = "CARPLAY_OVERVIEW".localizedString(
            value: "Overview",
            comment: "Title for overview button in CPTripPreviewTextConfiguration"
        )

        let defaultPreviewText = CPTripPreviewTextConfiguration(
            startButtonTitle: goTitle,
            additionalRoutesButtonTitle: alternativeRoutesTitle,
            overviewButtonTitle: overviewTitle
        )
        return defaultPreviewText
    }

    private func defaultTripPreviewBackButton() -> CPBarButton {
        let title = "CARPLAY_PREVIEW_BACK".localizedString(
            value: "Back",
            comment: "Title for trip preview back button"
        )
        let backButton = CPBarButton(title: title) { [weak self] (_: CPBarButton) in
            guard let self else { return }
            Task {
                await self.cancelRoutesPreview()
            }
        }
        return backButton
    }
}

// MARK: CPMapTemplateDelegate Methods

extension CarPlayManager: CPMapTemplateDelegate {
    @MainActor
    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        startedTrip trip: CPTrip,
        using routeChoice: CPRouteChoice
    ) {
        clearMapAnnotations()
        if let searchResult = routeChoice.searchResult {
            Task {
                let waypoint = Waypoint(
                    coordinate: searchResult.coordinate,
                    name: searchResult.name
                )
                await previewRoutes(to: waypoint)
            }
        } else if let navigationRoutes = routeChoice.navigationRoutes {
            startTrip(mapTemplate: mapTemplate, trip: trip, navigationRoutes: navigationRoutes)
        } else {
            preconditionFailure("CPRouteChoice should contain `RouteResponseUserInfo` struct.")
        }
    }

    @MainActor
    private func startTrip(
        mapTemplate: CPMapTemplate,
        trip: CPTrip,
        navigationRoutes: NavigationRoutes
    ) {
        guard let interfaceController,
              let carPlayMapViewController
        else {
            return
        }
        clearMapAnnotations()
        carPlayMapViewController.removeSearchResultsAnnotations()

        mapTemplate.hideTripPreviews()

        popToRootTemplate(interfaceController: interfaceController, animated: false) { [self] _, _ in
            let navigationMapTemplate = navigationMapTemplate()
            setRootTemplate(
                interfaceController: interfaceController,
                rootTemplate: navigationMapTemplate,
                animated: true
            ) { [weak self] _, _ in
                guard let self else { return }

                let carPlayNavigationViewController = carPlayNavigationViewControllerType.init(
                    accessToken: navigationProvider.coreConfig.credentials.navigation.accessToken,
                    core: navigationProvider.mapboxNavigation,
                    mapTemplate: navigationMapTemplate,
                    interfaceController: interfaceController,
                    manager: self,
                    styles: styles,
                    navigationRoutes: navigationRoutes
                )
                carPlayNavigationViewController.startNavigationSession(for: trip)
                carPlayNavigationViewController.delegate = self
                carPlayNavigationViewController.modalPresentationStyle = .fullScreen
                self.carPlayNavigationViewController = carPlayNavigationViewController

                carPlayNavigationViewController.loadViewIfNeeded()
                delegate?.carPlayManager(self, willPresent: carPlayNavigationViewController)

                carPlayMapViewController.present(carPlayNavigationViewController, animated: true) { [weak self] in
                    guard let self else { return }
                    delegate?.carPlayManager(self, didPresent: carPlayNavigationViewController)
                }

                removeRoutesFromMap()
            }
        }
    }

    func navigationMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let currentActivity: CarPlayActivity = .navigating
        mapTemplate.userInfo = [
            CarPlayManager.currentActivityKey: currentActivity,
        ]

        updateNavigationButtons(for: mapTemplate)

        return mapTemplate
    }

    @MainActor
    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        selectedPreviewFor trip: CPTrip,
        using routeChoice: CPRouteChoice
    ) {
        if let navigationRoutes = routeChoice.navigationRoutes {
            showcaseIfNeeded(routes: navigationRoutes, mapTemplate: mapTemplate, trip: trip, routeChoice: routeChoice)
        } else if let searchResult = routeChoice.searchResult {
            carPlayMapViewController?.showSearchResultsAnnotations(
                with: fetchedSearchResults,
                selectedResult: searchResult
            )
        } else {
            preconditionFailure("CPRouteChoice should contain `RouteResponseUserInfo` struct.")
        }
    }

    @MainActor
    @_spi(MapboxInternal)
    public func clearMapAnnotations() {
        fetchedSearchResults = []
        carPlayMapViewController?.removeSearchResultsAnnotations()
    }

    @MainActor
    private func showcaseIfNeeded(
        routes: NavigationRoutes?,
        mapTemplate: CPMapTemplate,
        trip: CPTrip,
        routeChoice: CPRouteChoice
    ) {
        guard let carPlayMapViewController, let routes else { return }
        let route = routes.mainRoute.route
        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(distance: route.distance).localized(),
            timeRemaining: route.expectedTravelTime
        )
        mapTemplate.updateEstimates(estimates, for: trip)

        let navigationMapView = carPlayMapViewController.navigationMapView
        navigationMapView.showcase(
            routes,
            routeAnnotationKinds: [.relativeDurationsOnAlternativeManuever]
        )
        self.routes = routes
        delegate?.carPlayManager(self, selectedPreviewFor: trip, using: routeChoice)
    }

    @MainActor
    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        guard let carPlayMapViewController else {
            return
        }
        removeRoutesFromMap()
        carPlayMapViewController.subscribeForFreeDriveNotifications()
        delegate?.carPlayManagerDidEndNavigation(self)
        delegate?.carPlayManagerDidEndNavigation(self, byCanceling: false)
    }

    @MainActor
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

    @MainActor
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        let traitCollection: UITraitCollection
        let currentActivity: CarPlayActivity
        if let carPlayNavigationViewController {
            currentActivity = .panningInNavigationMode
            traitCollection = carPlayNavigationViewController.traitCollection
        } else if let carPlayMapViewController {
            currentActivity = .panningInBrowsingMode
            traitCollection = carPlayMapViewController.traitCollection
        } else {
            assertionFailure("Panning interface is only supported for free-drive or active-guidance navigation.")
            return
        }

        // Whenever panning interface is shown (either in preview mode or during active navigation),
        // user should be given an opportunity to update buttons in `CPMapTemplate`.
        if let mapButtons = delegate?.carPlayManager(
            self,
            mapButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: currentActivity
        ) {
            mapTemplate.mapButtons = mapButtons
        } else {
            if let carPlayMapViewController {
                let closeButton = carPlayMapViewController.panningInterfaceDismissalButton(for: mapTemplate)
                carPlayMapViewController.dismissPanningButton = closeButton
                mapTemplate.mapButtons = [closeButton]
            }
        }

        if let leadingButtons = delegate?.carPlayManager(
            self,
            leadingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: currentActivity
        ) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }

        if let trailingButtons = delegate?.carPlayManager(
            self,
            trailingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: currentActivity
        ) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }

        self.currentActivity = currentActivity
        delegate?.carPlayManager(self, didShowPanningInterface: mapTemplate)
    }

    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        Task { @MainActor in
            if let carPlayMapViewController {
                let shouldShowRecenterButton = carPlayMapViewController.navigationMapView.navigationCamera
                    .currentCameraState == .idle
                carPlayMapViewController.recenterButton.isHidden = !shouldShowRecenterButton
            }

            delegate?.carPlayManager(self, willDismissPanningInterface: mapTemplate)
        }
    }

    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        guard let currentActivity = mapTemplate.currentActivity else { return }

        self.currentActivity = currentActivity

        updateNavigationButtons(for: mapTemplate)
        delegate?.carPlayManager(self, didDismissPanningInterface: mapTemplate)
    }

    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didUpdatePanGestureWithTranslation translation: CGPoint,
        velocity: CGPoint
    ) {
        // Map view panning is allowed in all states except routes preview.
        Task { @MainActor in
            if currentActivity == .previewing {
                return
            }

            // Continuously prevent navigation bar hiding whenever panning occurs.
            mapTemplate.automaticallyHidesNavigationBar = false

            updatePan(by: translation, mapTemplate: mapTemplate)
        }
    }

    @MainActor
    private func updatePan(by offset: CGPoint, mapTemplate: CPMapTemplate) {
        guard let navigationMapView = activeNavigationMapView else { return }

        navigationMapView.mapView.mapboxMap.setCamera(to: dragCameraOptions(with: offset, in: navigationMapView))
    }

    @MainActor
    private func dragCameraOptions(with offset: CGPoint, in navigationMapView: NavigationMapView) -> CameraOptions {
        let contentFrame = navigationMapView.bounds.inset(by: navigationMapView.mapView.safeAreaInsets)
        let centerPoint = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x + offset.x, y: centerPoint.y + offset.y)

        return navigationMapView.mapView.mapboxMap.dragCameraOptions(from: centerPoint, to: endCameraPoint)
    }

    public func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        Task { @MainActor in
            // In case if `CarPlayManager.carPlayNavigationViewController` is not `nil`, it means that
            // active-guidance navigation is currently in progress. Is so, panning should be applied for
            // `NavigationMapView` instance there.
            guard let navigationMapView = activeNavigationMapView else { return }

            // After `MapView` panning `NavigationCamera` should be moved to idle state to prevent any further changes.
            navigationMapView.navigationCamera.stop()

            // Determine the screen distance to pan by based on the distance from the visual center to the closest side.
            let contentFrame = navigationMapView.bounds.inset(by: navigationMapView.mapView.safeAreaInsets)
            let increment = min(navigationMapView.bounds.width, navigationMapView.bounds.height) / 2.0

            // Calculate the distance in physical units from the visual center to where it would be after panning
            // downwards.
            let downshiftedCenter = CGPoint(x: contentFrame.midX, y: contentFrame.midY + increment)
            let downshiftedCenterCoordinate = navigationMapView.mapView.mapboxMap.coordinate(for: downshiftedCenter)
            let cameraState = navigationMapView.mapView.mapboxMap.cameraState
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
    }

    private func setRootTemplate(
        interfaceController: CPInterfaceController?,
        rootTemplate: CPTemplate,
        animated: Bool
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setRootTemplate(
                interfaceController: interfaceController,
                rootTemplate: rootTemplate,
                animated: animated
            ) { _, error in
                if let error {
                    return continuation.resume(throwing: error)
                }
                continuation.resume()
            }
        }
    }

    func popToRootTemplate(
        interfaceController: CPInterfaceController?,
        animated: Bool
    ) async throws -> Bool {
        guard let interfaceController, interfaceController.templates.count > 1 else {
            return false
        }
        return try await interfaceController.popToRootTemplate(animated: animated)
    }

    private func popToRootTemplate(
        interfaceController: CPInterfaceController?,
        animated: Bool,
        completion: ((Bool, Error?) -> Void)?
    ) {
        guard let interfaceController, interfaceController.templates.count > 1 else {
            completion?(false, nil)
            return
        }

        interfaceController.popToRootTemplate(animated: animated, completion: completion)
    }

    private func setRootTemplate(
        interfaceController: CPInterfaceController?,
        rootTemplate: CPTemplate,
        animated: Bool,
        completion: ((Bool, Error?) -> Void)?
    ) {
        guard let interfaceController else {
            completion?(false, nil)
            return
        }

        interfaceController.setRootTemplate(
            rootTemplate,
            animated: animated,
            completion: completion
        )
    }

    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        displayStyleFor maneuver: CPManeuver
    ) -> CPManeuverDisplayStyle {
        if let visualInstruction = maneuver.userInfo as? VisualInstruction, visualInstruction.containsLaneIndications {
            return .symbolOnly
        }
        return []
    }

    /// Updates buttons (map buttons, leading and trailing navigation bar buttons) for provided `CPMapTemplate`.
    /// In case if delegate methods for certain ``CarPlayActivity`` return nil value, default buttons will be used:
    /// - Default map buttons include user tracking button (allows to switch between overview and following camera
    /// modes) and show feedback button.
    /// - Default leading navigation bar buttons include only mute/unmute button.
    /// - Default trailing navigation bar buttons include only exit active navigation button.
    ///
    /// - Parameter mapTemplate: `CPMapTemplate` instance, for which buttons update will be performed.
    private func updateNavigationButtons(for mapTemplate: CPMapTemplate) {
        Task { @MainActor in
            guard let currentActivity = mapTemplate.currentActivity else { return }

            let traitCollection: UITraitCollection

            if let carPlayNavigationViewController {
                traitCollection = carPlayNavigationViewController.traitCollection
            } else if let carPlayMapViewController {
                traitCollection = carPlayMapViewController.traitCollection
            } else {
                assertionFailure("Panning interface is only supported for free-drive or active-guidance navigation.")
                return
            }

            if let mapButtons = delegate?.carPlayManager(
                self,
                mapButtonsCompatibleWith: traitCollection,
                in: mapTemplate,
                for: currentActivity
            ) {
                mapTemplate.mapButtons = mapButtons
            } else {
                mapTemplate.mapButtons = [userTrackingButton, showFeedbackButton]
            }

            if let leadingButtons = delegate?.carPlayManager(
                self,
                leadingNavigationBarButtonsCompatibleWith: traitCollection,
                in: mapTemplate,
                for: currentActivity
            ) {
                mapTemplate.leadingNavigationBarButtons = leadingButtons
            } else {
                mapTemplate.leadingNavigationBarButtons = [muteButton, alternativeRoutesButton]
            }

            if let trailingButtons = delegate?.carPlayManager(
                self,
                trailingNavigationBarButtonsCompatibleWith: traitCollection,
                in: mapTemplate,
                for: currentActivity
            ) {
                mapTemplate.trailingNavigationBarButtons = trailingButtons
            } else {
                mapTemplate.trailingNavigationBarButtons = [exitButton]
            }
        }
    }

    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldShowNotificationFor maneuver: CPManeuver
    ) -> Bool {
        return delegate?.carPlayManager(
            self,
            shouldShowNotificationFor: maneuver,
            in: mapTemplate
        ) ?? false
    }

    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldShowNotificationFor navigationAlert: CPNavigationAlert
    ) -> Bool {
        return delegate?.carPlayManager(
            self,
            shouldShowNotificationFor: navigationAlert,
            in: mapTemplate
        ) ?? false
    }

    public func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        shouldUpdateNotificationFor maneuver: CPManeuver,
        with travelEstimates: CPTravelEstimates
    ) -> Bool {
        return delegate?.carPlayManager(
            self,
            shouldUpdateNotificationFor: maneuver,
            with: travelEstimates,
            in: mapTemplate
        ) ?? false
    }
}

// MARK: CarPlayNavigationViewControllerDelegate Methods

extension CarPlayManager: CarPlayNavigationViewControllerDelegate {
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        guidanceBackgroundColorFor style: UIUserInterfaceStyle
    ) -> UIColor? {
        delegate?.carPlayManager(self, guidanceBackgroundColorFor: style)
    }

    public func carPlayNavigationViewControllerWillDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    ) {
        delegate?.carPlayManagerWillEndNavigation(self, byCanceling: canceled)
    }

    @MainActor
    public func carPlayNavigationViewControllerDidDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    ) {
        guard let interfaceController else {
            return
        }

        // Dismiss the template for previous arrival UI when exit the navigation.
        interfaceController.dismissTemplate(animated: true, completion: nil)
        // Unset existing main map template (fixes an issue with the buttons)
        mainMapTemplate = nil

        // Then (re-)create and assign new map template
        let mapTemplate = previewMapTemplate()
        mainMapTemplate = mapTemplate

        setRootTemplate(
            interfaceController: interfaceController,
            rootTemplate: mapTemplate,
            animated: true
        ) { [self] _, _ in

            carPlayMapViewController?.subscribeForFreeDriveNotifications()

            self.carPlayNavigationViewController = nil
            delegate?.carPlayManagerDidEndNavigation(self)
            delegate?.carPlayManagerDidEndNavigation(self, byCanceling: canceled)
        }
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shouldPresentArrivalUIFor waypoint: Waypoint
    ) -> Bool {
        return delegate?.carPlayManager(self, shouldPresentArrivalUIFor: waypoint) ?? true
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        delegate?.carPlayManager(self, shapeFor: waypoints, legIndex: legIndex)
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> MapboxMaps.CircleLayer? {
        delegate?.carPlayManager(
            self,
            waypointCircleLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        delegate?.carPlayManager(
            self,
            waypointSymbolLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        return delegate?.carPlayManager(
            self,
            routeLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier,
            for: carPlayNavigationViewController
        )
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        return delegate?.carPlayManager(
            self,
            routeCasingLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier,
            for: carPlayNavigationViewController
        )
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        return delegate?.carPlayManager(
            self,
            routeRestrictedAreasLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier,
            for: carPlayNavigationViewController
        )
    }

    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        willAdd layer: Layer
    ) -> Layer? {
        return delegate?.carPlayManager(
            self,
            willAdd: layer,
            for: carPlayNavigationViewController
        )
    }
}

// MARK: CarPlayMapViewControllerDelegate Methods

extension CarPlayManager: CarPlayMapViewControllerDelegate {
    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayManager(
            self,
            routeLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier,
            for: carPlayMapViewController
        )
    }

    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayManager(
            self,
            routeCasingLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier,
            for: carPlayMapViewController
        )
    }

    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayManager(
            self,
            routeRestrictedAreasLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier,
            for: carPlayMapViewController
        )
    }

    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        willAdd layer: Layer
    ) -> Layer? {
        delegate?.carPlayManager(
            self,
            willAdd: layer,
            for: carPlayMapViewController
        )
    }

    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        delegate?.carPlayManager(self, shapeFor: waypoints, legIndex: legIndex)
    }

    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        delegate?.carPlayManager(
            self,
            waypointCircleLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        delegate?.carPlayManager(
            self,
            waypointSymbolLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    @_spi(MapboxInternal)
    public func carPlayMapViewController(
        _ carPlayMapViewController: CarPlayMapViewController,
        didSetup navigationMapView: NavigationMapView
    ) {
        delegate?.carPlayManager(self, didSetup: navigationMapView)
    }
}

// MARK: MapTemplateProviderDelegate Methods

extension CarPlayManager: MapTemplateProviderDelegate {
    func mapTemplateProvider(
        _ provider: MapTemplateProvider,
        mapTemplate: CPMapTemplate,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        return delegate?.carPlayManager(
            self,
            leadingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: activity
        )
    }

    func mapTemplateProvider(
        _ provider: MapTemplateProvider,
        mapTemplate: CPMapTemplate,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        return delegate?.carPlayManager(
            self,
            trailingNavigationBarButtonsCompatibleWith: traitCollection,
            in: mapTemplate,
            for: activity
        )
    }
}

// MARK: CPTemplateApplicationSceneDelegate Methods

extension CarPlayManager {
    @MainActor
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnectCarInterfaceController interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let shouldDisableIdleTimer = delegate?.carPlayManagerShouldDisableIdleTimer(self) ?? true
        if shouldDisableIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }

        let carPlayMapViewController = CarPlayMapViewController(core: core, styles: styles)
        carPlayMapViewController.startFreeDriveAutomatically = startFreeDriveAutomatically
        carPlayMapViewController.delegate = self
        window.rootViewController = carPlayMapViewController
        carWindow = window
        let mapTemplate = previewMapTemplate()
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false, completion: nil)

        eventsManager.sendCarPlayConnectEvent()

        subscribeForNotifications()
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
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
        routes = nil
    }
}

// MARK: CarPlayManager Constants

extension CarPlayManager {
    static let currentActivityKey = "com.mapbox.navigation.currentActivity"
}
