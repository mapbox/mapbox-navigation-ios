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

    /// Controls whether the speed limit view is hidden while the CarPlay navigation bar or map buttons are visible.
    ///
    /// This property is `true` by default. Setting it to `false` does not affect visibility rules for panning, route
    /// preview, non-following camera states, or an available recenter action.
    @_spi(ExperimentalMapboxAPI)
    @MainActor
    public var hidesSpeedLimitViewWithMapControls = true {
        didSet {
            carPlayMapViewController?.hidesSpeedLimitViewWithMapControls = hidesSpeedLimitViewWithMapControls
            carPlayNavigationViewController?.hidesSpeedLimitViewWithMapControls = hidesSpeedLimitViewWithMapControls
        }
    }

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
    @MainActor private var hasStartedNavigationCleanup = false

    /// Programatically begins a CarPlay turn-by-turn navigation session.
    /// - Parameter currentLocation: The current location of the user. This will be used to initally draw SignInViewthe
    /// current
    /// location icon.
    public func beginNavigationWithCarPlay(using currentLocation: CLLocationCoordinate2D) {
        Task { @MainActor in
            guard let routes = core.tripSession().currentNavigationRoutes,
                  var trip = await CPTrip(
                      routes: routes,
                      locale: locale,
                      unitMeasurementSystem: unitMeasurementSystem
                  )
            else {
                return
            }
            trip = delegate?.carPlayManager(self, willPreview: trip) ?? trip

            if let mapTemplate = mainMapTemplate, let routeChoice = trip.routeChoices.first {
                self.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
            }
        }
    }

    private let navigationProvider: MapboxNavigationProvider
    private let core: MapboxNavigation
    private var cameraStateCancellable: AnyCancellable?

    // Intentionally a reference type: object identity is the transaction token checked after each await.
    @MainActor
    private final class PreviewTransition {
        let template: CPMapTemplate
        let activityBeforePreview: CarPlayActivity?
        var searchResults: [SearchResultRecord]

        init(
            template: CPMapTemplate,
            activityBeforePreview: CarPlayActivity?,
            searchResults: [SearchResultRecord]
        ) {
            self.template = template
            self.activityBeforePreview = activityBeforePreview
            self.searchResults = searchResults
        }
    }

    @MainActor
    private struct PreviewSession {
        let template: CPMapTemplate
        let activityBeforePreview: CarPlayActivity?
        var searchResults: [SearchResultRecord]
    }

    // Intentionally a reference type: object identity prevents overlapping updates from committing out of order.
    @MainActor
    private final class PreviewUpdate {
        var session: PreviewSession

        init(session: PreviewSession) {
            self.session = session
        }
    }

    @MainActor
    private final class PreviewCancellation {
        let transition: PreviewTransition?
        let update: PreviewUpdate?
        let template: CPMapTemplate?
        let activityBeforePreview: CarPlayActivity?
        let popToRoot: Bool
        // Cancellation and an in-flight CarPlay operation can finish in either order. Remain in `.cancelling`
        // until both sides have completed.
        var operationFinished: Bool
        var cancellationFinished = false

        init(
            transition: PreviewTransition? = nil,
            update: PreviewUpdate? = nil,
            template: CPMapTemplate?,
            activityBeforePreview: CarPlayActivity?,
            popToRoot: Bool
        ) {
            self.transition = transition
            self.update = update
            self.template = template
            self.activityBeforePreview = activityBeforePreview
            self.popToRoot = popToRoot
            self.operationFinished = transition == nil && update == nil
        }
    }

    @MainActor
    private enum PreviewState {
        case inactive
        case presenting(PreviewTransition)
        case presented(PreviewSession)
        case updating(PreviewUpdate)
        case cancelling(PreviewCancellation)
    }

    @MainActor
    private enum PreviewRequest {
        case searchResults([SearchResultRecord])
        case trip(CPTrip)
    }

    @MainActor
    private final class PendingPreviewRequest {
        let request: PreviewRequest
        let continuation: CheckedContinuation<Void, Error>

        init(
            request: PreviewRequest,
            continuation: CheckedContinuation<Void, Error>
        ) {
            self.request = request
            self.continuation = continuation
        }
    }

    @MainActor private var previewState: PreviewState = .inactive
    @MainActor private var pendingPreviewRequest: PendingPreviewRequest?

    var coreConfig: CoreConfig {
        navigationProvider.coreConfig
    }

    private var directionsOptions: DirectionsOptions? {
        routes?.mainRoute.directionsOptions
    }

    private var locale: Locale {
        directionsOptions?.locale ?? coreConfig.locale
    }

    var unitMeasurementSystem: UnitMeasurementSystem {
        directionsOptions?.unitMeasurementSystem ?? locale.unitMeasurementSystem
    }

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

    @MainActor
    func subscribeForCameraStateNotifications() {
        guard let navigationCamera = activeNavigationMapView?.navigationCamera else {
            cameraStateCancellable = nil
            return
        }

        cameraStateCancellable = navigationCamera.cameraStates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.navigationCameraStateDidChange($0)
            }

        // `cameraStates` does not replay its latest value. Synchronize immediately in case the transition
        // completed before the subscription was installed, for example while presenting the browsing map.
        navigationCameraStateDidChange(navigationCamera.currentCameraState)
    }

    func unsubscribeFromCameraStateNotifications() {
        cameraStateCancellable = nil
    }

    @MainActor
    private func updateWayNameViewVisibility(cameraState: NavigationCameraState? = nil) {
        if let carPlayNavigationViewController {
            carPlayNavigationViewController.updateWayNameViewVisibility(cameraState: cameraState)
        } else {
            carPlayMapViewController?.updateWayNameViewVisibility(cameraState: cameraState)
        }
    }

    @MainActor
    private func setCurrentActivity(_ currentActivity: CarPlayActivity?) {
        self.currentActivity = currentActivity
        if let carPlayNavigationViewController {
            carPlayNavigationViewController.updateSpeedLimitViewVisibility()
            carPlayNavigationViewController.updateWayNameViewVisibility()
            return
        }
        carPlayMapViewController?.currentActivity = currentActivity
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

        if let carPlayNavigationViewController {
            carPlayNavigationViewController.updateSpeedLimitViewVisibility()
        } else {
            carPlayMapViewController?.updateSpeedLimitViewVisibility()
        }
        updateWayNameViewVisibility(cameraState: state)

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

    // TODO: @available(*, deprecated, message: "Use browsingNavigationMapView and guidanceNavigationMapView")
    // if browsingNavigationMapView and guidanceNavigationMapView become public
    /// The main `NavigationMapView` displayed inside CarPlay.
    @MainActor
    public var navigationMapView: NavigationMapView? {
        return carPlayMapViewController?.navigationMapView
    }

    @MainActor
    @_spi(MapboxCarPlayInternal)
    public var browsingNavigationMapView: NavigationMapView? {
        return carPlayMapViewController?.navigationMapView
    }

    @MainActor
    @_spi(MapboxCarPlayInternal)
    public var guidanceNavigationMapView: NavigationMapView? {
        return carPlayNavigationViewController?.navigationMapView
    }

    @MainActor
    @_spi(MapboxCarPlayInternal)
    public var activeNavigationMapView: NavigationMapView? {
        guidanceNavigationMapView ?? browsingNavigationMapView
    }

    var mapTemplateProvider: MapTemplateProvider {
        didSet {
            mapTemplateProvider.delegate = self
        }
    }

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

    @_spi(MapboxCarPlayInternal)
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

    @MainActor
    @available(*, deprecated, renamed: "templateApplicationScene(_:didConnect:to:)")
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnectCarInterfaceController interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        handleDidConnect(interfaceController: interfaceController, to: window)
    }

    @available(*, deprecated, renamed: "templateApplicationScene(_:didDisconnect:from:)")
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        let disconnect = { @MainActor in
            self.handleDidDisconnect(interfaceController: interfaceController, from: window)
        }
        if Thread.isMainThread {
            MainActor.assumingIsolated(disconnect)
        } else {
            DispatchQueue.main.sync {
                MainActor.assumingIsolated(disconnect)
            }
        }
    }
}

// MARK: InterfaceController handling Methods

extension CarPlayManager {
    /// Creates map options for a map rendered on the connected CarPlay display.
    ///
    /// `MapOptions` otherwise uses `UIScreen.main.nativeScale`, which describes the phone screen. A map hosted by
    /// `CPWindow` must instead use that window's screen scale; the renderer captures this value during initialization
    /// and cannot update it after the map moves into the CarPlay window.
    private func mapOptions(for window: UIWindow) -> MapOptions {
        MapOptions(pixelRatio: window.screen.nativeScale)
    }

    private func usesCompactMapOverlays(for window: UIWindow) -> Bool {
        CarPlayUtilities.usesCompactMapOverlays(forNativeScreenSize: window.screen.nativeBounds.size)
    }

    @MainActor
    func handleDidConnect(interfaceController: CPInterfaceController, to window: CPWindow) {
        CarPlayManager.isConnected = true
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let shouldDisableIdleTimer = delegate?.carPlayManagerShouldDisableIdleTimer(self) ?? true
        if shouldDisableIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }
        let carPlayMapViewController = CarPlayMapViewController(
            core: core,
            styles: styles,
            mapOptions: mapOptions(for: window),
            usesCompactMapOverlays: usesCompactMapOverlays(for: window)
        )
        carPlayMapViewController.userInfo = eventsManager.userInfo
        carPlayMapViewController.startFreeDriveAutomatically = startFreeDriveAutomatically
        carPlayMapViewController.hidesSpeedLimitViewWithMapControls = hidesSpeedLimitViewWithMapControls
        carPlayMapViewController.delegate = self
        window.rootViewController = carPlayMapViewController
        carWindow = window

        let mapTemplate = browseAndFreeDriveMapTemplate()
        mainMapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: false, completion: nil)

        eventsManager.sendCarPlayConnectEvent()

        subscribeForCameraStateNotifications()
    }

    @MainActor
    func handleDidDisconnect(interfaceController: CPInterfaceController, from window: CPWindow) {
        cancelPendingPreviewRequest()
        clearPreviewState()
        // A push that was in flight on the disconnected interface controller may never complete. Do not keep the
        // manager in `.cancelling` waiting for it; a late completion is rejected by its transition identity check.
        previewState = .inactive

        CarPlayManager.isConnected = false
        self.interfaceController = nil

        window.rootViewController = nil
        window.isHidden = true
        window.removeFromSuperview()

        mainMapTemplate = nil
        carWindow = nil

        eventsManager.sendCarPlayDisconnectEvent()

        idleTimerCancellable = nil

        unsubscribeFromCameraStateNotifications()
    }

    @MainActor
    func browseAndFreeDriveMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let currentActivity: CarPlayActivity = .browsing
        mapTemplate.currentActivity = currentActivity
        setCurrentActivity(currentActivity)

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

            self.setCurrentActivity(template.currentActivity)
        }
    }

    public func templateDidAppear(_ template: CPTemplate, animated: Bool) {
        delegate?.carPlayManager(self, templateDidAppear: template, animated: animated)

        MainActor.assumingIsolated {
            // Initial preview presentation can briefly expose the root template. Wait for that transaction instead
            // of treating the intermediate appearance as a manual return to browsing.
            guard interfaceController?.topTemplate == mainMapTemplate,
                  template == interfaceController?.rootTemplate,
                  !isPreviewTransitioning
            else {
                return
            }
            clearPreviewState()
        }
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
    /// Upon successful calculation a preview template is pushed onto the template navigation hierarchy if no preview
    /// is currently presented. Otherwise the presented preview template is updated in place, and any templates pushed
    /// above it are popped first.
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
    /// Upon successful calculation a preview template is pushed onto the template navigation hierarchy if no preview
    /// is currently presented. Otherwise the presented preview template is updated in place, and any templates pushed
    /// above it are popped first.
    /// - Parameters:
    ///   - destination: A final destination `Waypoint`.
    public func previewRoutes(to destination: Waypoint) async {
        await previewRoutes(to: destination, searchResultRecord: nil)
    }

    /// Same as ``previewRoutes(to:)`` but additionally attaches a ``SearchResultRecord`` to every route choice,
    /// retrievable from `CarPlayManagerDelegate.carPlayManager(_:selectedPreviewFor:using:)` via
    /// ``CPRouteChoice/searchResult``.
    @_spi(MapboxCarPlaySearchInternal)
    public func previewRoutes(to destination: Waypoint, searchResultRecord: SearchResultRecord?) async {
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

        await previewRoutes(between: [origin, destination], searchResultRecord: searchResultRecord)
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
        await previewRoutes(between: waypoints, searchResultRecord: nil)
    }

    @_spi(MapboxCarPlaySearchInternal)
    public func previewRoutes(between waypoints: [Waypoint], searchResultRecord: SearchResultRecord?) async {
        let options = NavigationRouteOptions(waypoints: waypoints)
        await previewRoutes(for: options, searchResultRecord: searchResultRecord)
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
        await previewRoutes(for: options, searchResultRecord: nil)
    }

    @_spi(MapboxCarPlaySearchInternal)
    public func previewRoutes(for options: RouteOptions, searchResultRecord: SearchResultRecord?) async {
        let task = await core.routingProvider().calculateRoutes(options: options)
        await didCalculate(task, for: options, searchResultRecord: searchResultRecord)
    }

    /// Allows to preview routes for a specific `NavigationRoutes` object.
    /// - Parameter routes: `NavigationRoutes` object, containing all information of routes that will be previewed.
    public func previewRoutes(for routes: NavigationRoutes) async {
        await previewRoutes(for: routes, searchResultRecord: nil)
    }

    @_spi(MapboxCarPlaySearchInternal)
    public func previewRoutes(for routes: NavigationRoutes, searchResultRecord: SearchResultRecord?) async {
        guard shouldPreviewRoutes(for: routes) else { return }
        guard let trip = await CPTrip(
            routes: routes,
            locale: locale,
            unitMeasurementSystem: unitMeasurementSystem,
            searchResultRecord: searchResultRecord
        ) else {
            return
        }
        try? await previewRoutes(for: trip)
    }

    /// Allows to cancel routes preview on CarPlay .
    @MainActor
    public func cancelRoutesPreview() async {
        // Guidance has already consumed the preview, even while its template transition is still in flight.
        guard currentActivity != .navigating, hasPreviewState else { return }

        // Historically these callbacks were emitted only after a route was selected. Cleanup now also handles previews
        // canceled before route selection, interrupted presentations, and POI-only previews without changing that
        // callback contract.
        let shouldNotifyDelegate = routes != nil
        carPlayMapViewController?.isDismissingRoutePreview = true
        defer {
            carPlayMapViewController?.isDismissingRoutePreview = false
        }

        clearMapAnnotations()
        var configuration = CarPlayManagerCancelPreviewConfiguration()
        if shouldNotifyDelegate {
            delegate?.carPlayManagerWillCancelPreview(self, configuration: &configuration)
        }

        let cancellation = beginPreviewCancellation(popToRoot: configuration.popToRoot)
        discardPreviewContent(template: cancellation.template, clearAnnotations: false)
        restoreActivityAfterPreview(
            cancellation.activityBeforePreview,
            template: cancellation.template
        )

        if configuration.popToRoot {
            do {
                _ = try await popToRootTemplate(interfaceController: interfaceController, animated: true)
            } catch {
                Log.error(
                    "Failed to pop to the CarPlay root template while canceling preview: \(error.localizedDescription)",
                    category: .carPlay
                )
                if interfaceController?.topTemplate === cancellation.template {
                    do {
                        try await interfaceController?.popTemplate(animated: true)
                    } catch {
                        Log.error(
                            "Failed to remove the CarPlay preview template after popping to root failed: "
                                + error.localizedDescription,
                            category: .carPlay
                        )
                    }
                }
            }
        }
        cancellation.cancellationFinished = true
        finishPreviewCancellationIfPossible(cancellation)

        if shouldNotifyDelegate {
            delegate?.carPlayManagerDidCancelPreview(self)
        }
        await performPendingPreviewRequestIfPossible()
    }

    func shouldPreviewRoutes(for routes: NavigationRoutes) -> Bool {
        guard self.routes?.mainRoute == routes.mainRoute else { return true }
        return self.routes?.alternativeRoutes != routes.alternativeRoutes
    }

    @MainActor
    private var hasPreviewState: Bool {
        if case .inactive = previewState {
            // Keep defensive checks for content created by delegates or older lifecycle paths.
            return routes != nil
                || currentActivity == .previewing
                || carPlayMapViewController?.hasSearchResultAnnotations == true
        }
        return true
    }

    @MainActor
    private var isPreviewTransitioning: Bool {
        switch previewState {
        case .presenting, .updating, .cancelling:
            return true
        case .inactive, .presented:
            return false
        }
    }

    @MainActor
    private func submitPreviewRequest(_ request: PreviewRequest) async throws {
        if isPreviewTransitioning {
            try await withCheckedThrowingContinuation { continuation in
                pendingPreviewRequest?.continuation.resume(throwing: CancellationError())
                pendingPreviewRequest = PendingPreviewRequest(
                    request: request,
                    continuation: continuation
                )
            }
            return
        }

        // A request submitted after a transition settled is newer than one waiting for its scheduled drain.
        cancelPendingPreviewRequest()
        do {
            try await performPreviewRequest(request)
            await performPendingPreviewRequestIfPossible()
        } catch {
            await performPendingPreviewRequestIfPossible()
            throw error
        }
    }

    @MainActor
    private func performPreviewRequest(_ request: PreviewRequest) async throws {
        switch request {
        case .searchResults(let searchResults):
            try await performPreviewRoutes(with: searchResults)
        case .trip(let trip):
            try await performPreviewRoutes(for: trip)
        }
    }

    @MainActor
    private func performPendingPreviewRequestIfPossible() async {
        guard !isPreviewTransitioning else { return }
        guard currentActivity != .navigating, interfaceController != nil else {
            cancelPendingPreviewRequest()
            return
        }
        guard let pendingPreviewRequest else { return }
        self.pendingPreviewRequest = nil

        do {
            try await performPreviewRequest(pendingPreviewRequest.request)
            pendingPreviewRequest.continuation.resume()
        } catch {
            pendingPreviewRequest.continuation.resume(throwing: error)
        }
        await performPendingPreviewRequestIfPossible()
    }

    @MainActor
    private func schedulePendingPreviewRequestIfPossible() {
        Task { @MainActor [weak self] in
            await self?.performPendingPreviewRequestIfPossible()
        }
    }

    @MainActor
    private func cancelPendingPreviewRequest() {
        pendingPreviewRequest?.continuation.resume(throwing: CancellationError())
        pendingPreviewRequest = nil
    }

    @MainActor
    private var fetchedSearchResults: [SearchResultRecord] {
        get {
            switch previewState {
            case .presenting(let transition):
                return transition.searchResults
            case .presented(let session):
                return session.searchResults
            case .updating(let update):
                return update.session.searchResults
            case .cancelling(let cancellation):
                return cancellation.transition?.searchResults
                    ?? cancellation.update?.session.searchResults
                    ?? []
            case .inactive:
                return []
            }
        }
        set {
            switch previewState {
            case .presenting(let transition):
                transition.searchResults = newValue
            case .presented(var session):
                session.searchResults = newValue
                previewState = .presented(session)
            case .updating(let update):
                update.session.searchResults = newValue
            case .cancelling(let cancellation):
                if let transition = cancellation.transition {
                    transition.searchResults = newValue
                } else {
                    cancellation.update?.session.searchResults = newValue
                }
            case .inactive:
                break
            }
        }
    }

    @MainActor
    private func beginPreviewCancellation(popToRoot: Bool) -> PreviewCancellation {
        if case .cancelling(let cancellation) = previewState {
            return cancellation
        }

        let cancellation: PreviewCancellation
        switch previewState {
        case .presenting(let transition):
            cancellation = PreviewCancellation(
                transition: transition,
                template: transition.template,
                activityBeforePreview: transition.activityBeforePreview,
                popToRoot: popToRoot
            )
        case .presented(let session):
            cancellation = PreviewCancellation(
                template: session.template,
                activityBeforePreview: session.activityBeforePreview,
                popToRoot: popToRoot
            )
        case .updating(let update):
            cancellation = PreviewCancellation(
                update: update,
                template: update.session.template,
                activityBeforePreview: update.session.activityBeforePreview,
                popToRoot: popToRoot
            )
        case .inactive:
            let topPreviewTemplate = (interfaceController?.topTemplate as? CPMapTemplate).flatMap {
                $0.currentActivity == .previewing ? $0 : nil
            }
            cancellation = PreviewCancellation(
                template: topPreviewTemplate,
                activityBeforePreview: mainMapTemplate?.currentActivity,
                popToRoot: popToRoot
            )
        case .cancelling:
            preconditionFailure("Handled above.")
        }

        previewState = .cancelling(cancellation)
        return cancellation
    }

    @MainActor
    private func finishPreviewCancellationIfPossible(_ cancellation: PreviewCancellation) {
        guard cancellation.operationFinished, cancellation.cancellationFinished,
              case .cancelling(let currentCancellation) = previewState,
              currentCancellation === cancellation
        else {
            return
        }
        previewState = .inactive
        schedulePendingPreviewRequestIfPossible()
    }

    @MainActor
    private func discardPreviewContent(
        template: CPMapTemplate?,
        clearAnnotations: Bool = true
    ) {
        template?.hideTripPreviews()
        // A failed or interrupted presentation may have placed a preview on the stack before it was committed above.
        if let topMapTemplate = interfaceController?.topTemplate as? CPMapTemplate,
           topMapTemplate !== template,
           topMapTemplate.currentActivity == .previewing
        {
            topMapTemplate.hideTripPreviews()
        }

        routes = nil
        navigationMapView?.removeRoutes()
        if clearAnnotations {
            clearMapAnnotations()
        }
    }

    @MainActor
    private func restoreActivityAfterPreview(
        _ activityBeforePreview: CarPlayActivity?,
        template: CPMapTemplate?
    ) {
        var restoredActivity = mainMapTemplate?.currentActivity ?? activityBeforePreview ?? .browsing
        // Preserve the root template's live state, including its panning history. Only rewrite it when stale preview
        // state leaked onto the browsing template.
        if restoredActivity == .previewing {
            restoredActivity = activityBeforePreview == .previewing
                ? .browsing
                : activityBeforePreview ?? .browsing
            mainMapTemplate?.currentActivity = restoredActivity
        }
        if template !== mainMapTemplate {
            template?.currentActivity = restoredActivity
        }
        setCurrentActivity(restoredActivity)
        navigationMapView?.navigationCamera.update(cameraState: .following)
    }

    @MainActor
    private func clearPreviewState() {
        guard hasPreviewState else { return }

        let cancellation = beginPreviewCancellation(popToRoot: true)
        let wasDismissingRoutePreview = carPlayMapViewController?.isDismissingRoutePreview ?? false
        carPlayMapViewController?.isDismissingRoutePreview = true
        discardPreviewContent(template: cancellation.template)
        restoreActivityAfterPreview(
            cancellation.activityBeforePreview,
            template: cancellation.template
        )
        carPlayMapViewController?.isDismissingRoutePreview = wasDismissingRoutePreview
        cancellation.cancellationFinished = true
        finishPreviewCancellationIfPossible(cancellation)
    }

    // POI previews discard search/list templates before their initial push; route previews preserve the existing stack.
    private enum InitialPreviewStackPreparation: Equatable {
        case currentStack
        case popToRoot
    }

    @MainActor
    private func presentInitialPreviewTemplate(
        _ template: CPMapTemplate,
        using interfaceController: CPInterfaceController,
        stackPreparation: InitialPreviewStackPreparation,
        searchResults: [SearchResultRecord]
    ) async throws {
        guard case .inactive = previewState else {
            template.hideTripPreviews()
            throw CancellationError()
        }

        let transition = PreviewTransition(
            template: template,
            activityBeforePreview: currentActivity,
            searchResults: searchResults
        )
        previewState = .presenting(transition)

        do {
            if stackPreparation == .popToRoot {
                do {
                    _ = try await popToRootTemplate(interfaceController: interfaceController, animated: false)
                } catch {
                    try await ensurePreviewPresentationIsCurrent(
                        transition,
                        interfaceController: interfaceController
                    )
                    Log.error(
                        "Failed to prepare the CarPlay template stack before presenting a preview; "
                            + "continuing with the current stack: \(error.localizedDescription)",
                        category: .carPlay
                    )
                }
            }
            try await ensurePreviewPresentationIsCurrent(
                transition,
                interfaceController: interfaceController
            )

            try await interfaceController.pushTemplate(template, animated: true)
            try await ensurePreviewPresentationIsCurrent(
                transition,
                interfaceController: interfaceController
            )

            previewState = .presented(
                PreviewSession(
                    template: template,
                    activityBeforePreview: transition.activityBeforePreview,
                    searchResults: transition.searchResults
                )
            )
            setCurrentActivity(.previewing)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            template.hideTripPreviews()
            if case .cancelling(let cancellation) = previewState,
               cancellation.transition === transition
            {
                await discardInvalidatedPreviewOperation(
                    cancellation,
                    using: interfaceController
                )
                throw CancellationError()
            }

            guard case .presenting(let currentTransition) = previewState,
                  currentTransition === transition
            else {
                throw CancellationError()
            }
            if interfaceController.topTemplate === template {
                try? await interfaceController.popTemplate(animated: false)
            }
            if stackPreparation == .popToRoot {
                _ = try? await popToRootTemplate(interfaceController: interfaceController, animated: false)
            }
            previewState = .inactive
            discardPreviewContent(template: template)
            restoreActivityAfterPreview(
                transition.activityBeforePreview,
                template: template
            )
            Log.error(
                "Failed to present a CarPlay preview; discarded incomplete preview state: \(error.localizedDescription)",
                category: .carPlay
            )
            throw error
        }
    }

    @MainActor
    private func ensurePreviewPresentationIsCurrent(
        _ transition: PreviewTransition,
        interfaceController: CPInterfaceController
    ) async throws {
        if case .presenting(let currentTransition) = previewState,
           currentTransition === transition
        {
            return
        }

        if case .cancelling(let cancellation) = previewState,
           cancellation.transition === transition
        {
            await discardInvalidatedPreviewOperation(
                cancellation,
                using: interfaceController
            )
        }
        throw CancellationError()
    }

    @MainActor
    private func discardInvalidatedPreviewOperation(
        _ cancellation: PreviewCancellation,
        using interfaceController: CPInterfaceController
    ) async {
        cancellation.template?.hideTripPreviews()

        do {
            if cancellation.popToRoot {
                _ = try await popToRootTemplate(interfaceController: interfaceController, animated: false)
            } else if interfaceController.topTemplate === cancellation.template {
                try await interfaceController.popTemplate(animated: false)
            }
        } catch {
            Log.error(
                "Failed to remove an invalidated CarPlay preview operation: \(error.localizedDescription)",
                category: .carPlay
            )
            if interfaceController.topTemplate === cancellation.template {
                try? await interfaceController.popTemplate(animated: false)
            }
        }
        cancellation.operationFinished = true
        finishPreviewCancellationIfPossible(cancellation)
    }

    @MainActor
    private func previewTemplate(
        traitCollection: UITraitCollection,
        interfaceController: CPInterfaceController
    ) async throws -> (template: CPMapTemplate, isPresented: Bool) {
        switch previewState {
        case .inactive:
            return (
                mapTemplateProvider.previewMapTemplate(
                    traitCollection: traitCollection,
                    mapDelegate: self
                ),
                false
            )
        case .presented(let session):
            guard interfaceController.templates.contains(where: { $0 === session.template }) else {
                // The application may have replaced the stack without revealing the root template. Do not keep
                // updating a detached preview session that can no longer become visible.
                session.template.hideTripPreviews()
                previewState = .inactive
                return (
                    mapTemplateProvider.previewMapTemplate(
                        traitCollection: traitCollection,
                        mapDelegate: self
                    ),
                    false
                )
            }

            // Templates pushed above the preview are popped before it is updated, so the update is visible. This
            // matches the previous behavior, where the top template was popped before a fresh preview was pushed.
            var currentSession = session
            if interfaceController.topTemplate !== session.template {
                currentSession = try await revealPreviewSession(session, using: interfaceController)
            }
            // Reset route-only state before the delegate reconfigures the template so that a back button provided by
            // the delegate survives the update.
            currentSession.template.backButton = nil
            mapTemplateProvider.configurePreviewMapTemplate(
                currentSession.template,
                traitCollection: traitCollection,
                mapDelegate: self
            )
            return (currentSession.template, true)
        case .presenting, .updating, .cancelling:
            throw CancellationError()
        }
    }

    @MainActor
    private func revealPreviewSession(
        _ session: PreviewSession,
        using interfaceController: CPInterfaceController
    ) async throws -> PreviewSession {
        let update = PreviewUpdate(session: session)
        previewState = .updating(update)

        do {
            _ = try await interfaceController.pop(to: session.template, animated: false)
            try await ensurePreviewUpdateIsCurrent(update, interfaceController: interfaceController)
            let updatedSession = update.session
            previewState = .presented(updatedSession)
            return updatedSession
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if case .cancelling(let cancellation) = previewState,
               cancellation.update === update
            {
                await discardInvalidatedPreviewOperation(
                    cancellation,
                    using: interfaceController
                )
                throw CancellationError()
            }

            guard case .updating(let currentUpdate) = previewState,
                  currentUpdate === update
            else {
                throw CancellationError()
            }
            previewState = .presented(update.session)
            throw error
        }
    }

    @MainActor
    private func ensurePreviewUpdateIsCurrent(
        _ update: PreviewUpdate,
        interfaceController: CPInterfaceController
    ) async throws {
        if case .updating(let currentUpdate) = previewState,
           currentUpdate === update
        {
            return
        }

        if case .cancelling(let cancellation) = previewState,
           cancellation.update === update
        {
            await discardInvalidatedPreviewOperation(
                cancellation,
                using: interfaceController
            )
        }
        throw CancellationError()
    }

    @MainActor
    private func commitUpdatedPreview(
        _ template: CPMapTemplate,
        searchResults: [SearchResultRecord]
    ) {
        guard case .presented(var session) = previewState,
              session.template === template
        else {
            return
        }
        session.searchResults = searchResults
        previewState = .presented(session)
        setCurrentActivity(.previewing)
    }

    @MainActor
    @_spi(MapboxCarPlaySearchInternal)
    public func previewRoutes(with searchResults: [SearchResultRecord]) async throws {
        try await submitPreviewRequest(.searchResults(searchResults))
    }

    @MainActor
    private func performPreviewRoutes(with searchResults: [SearchResultRecord]) async throws {
        guard let traitCollection = (carWindow?.rootViewController as? CarPlayMapViewController)?.traitCollection,
              let interfaceController
        else {
            return
        }

        let preview = try await previewTemplate(
            traitCollection: traitCollection,
            interfaceController: interfaceController
        )
        let template = preview.template

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

        let previewText = defaultTripPreviewTextConfiguration()

        template.showTripPreviews(
            trips,
            selectedTrip: trips.first,
            textConfiguration: previewText
        )

        for dataForPreview in dataForPreviews {
            guard let estimates = dataForPreview.estimates else { continue }
            template.updateEstimates(estimates, for: dataForPreview.trip)
        }

        if preview.isPresented {
            commitUpdatedPreview(template, searchResults: searchResults)
        } else {
            try await presentInitialPreviewTemplate(
                template,
                using: interfaceController,
                stackPreparation: .popToRoot,
                searchResults: searchResults
            )
        }

        routes = nil
        navigationMapView?.removeRoutes()
        carPlayMapViewController?.showSearchResultsAnnotations(with: searchResults, selectedResult: searchResults.first)
    }

    @MainActor
    func previewRoutes(for trip: CPTrip) async throws {
        try await submitPreviewRequest(.trip(trip))
    }

    @MainActor
    private func performPreviewRoutes(for trip: CPTrip) async throws {
        guard let traitCollection = (carWindow?.rootViewController as? CarPlayMapViewController)?.traitCollection,
              let interfaceController
        else {
            return
        }

        let modifiedTrip = delegate?.carPlayManager(self, willPreview: trip) ?? trip

        let preview = try await previewTemplate(
            traitCollection: traitCollection,
            interfaceController: interfaceController
        )
        let previewMapTemplate = preview.template

        var previewText = defaultTripPreviewTextConfiguration()
        if let customPreviewText = delegate?.carPlayManager(self, willPreview: modifiedTrip, with: previewText) {
            previewText = customPreviewText
        }

        previewMapTemplate.backButton = defaultTripPreviewBackButton()
        previewMapTemplate.showTripPreviews([modifiedTrip], textConfiguration: previewText)

        if preview.isPresented {
            commitUpdatedPreview(previewMapTemplate, searchResults: [])
        } else {
            try await presentInitialPreviewTemplate(
                previewMapTemplate,
                using: interfaceController,
                stackPreparation: .currentStack,
                searchResults: []
            )
        }
        clearMapAnnotations()
    }

    func removeRoutesFromBrowsingMap() {
        MainActor.assumingIsolated {
            routes = nil
            guard let navigationMapView = carPlayMapViewController?.navigationMapView else { return }
            navigationMapView.removeRoutes()
        }
    }

    func didCalculate(
        _ task: Task<NavigationRoutes, Error>,
        for routeOptions: RouteOptions,
        searchResultRecord: SearchResultRecord? = nil
    ) async {
        do {
            let routes = try await task.value
            await previewRoutes(for: routes, searchResultRecord: searchResultRecord)
        } catch {
            guard let delegate, let alert = delegate.carPlayManager(
                self,
                didFailToFetchRouteBetween: routeOptions.waypoints,
                options: routeOptions,
                error: error
            ) else {
                return
            }

            let mapTemplate = await interfaceController?.rootTemplate as? CPMapTemplate
            _ = try? await popToRootTemplate(interfaceController: interfaceController, animated: true)
            await mapTemplate?.present(navigationAlert: alert, animated: true)
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
        let title = "NAVIGATION_REPORT_CANCEL".localizedString(
            value: "Cancel",
            comment: "Title for trip preview cancel button"
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
        // Check `navigationRoutes` first: if it's populated, routes have already been calculated and the user tapped
        // "Navigate", so start the trip. Only fall back to the `searchResult`-only branch when routes haven't been
        // calculated yet (the category-search flow) — that branch re-previews routes for the chosen search result.
        // Both can be populated together when Dash threads a `SearchResultRecord` through `previewRoutes(to:)`.
        if let navigationRoutes = routeChoice.navigationRoutes {
            startTrip(mapTemplate: mapTemplate, trip: trip, navigationRoutes: navigationRoutes)
        } else if let searchResult = routeChoice.searchResultRecord {
            Task {
                let waypoint = Waypoint(
                    coordinate: searchResult.coordinate,
                    name: searchResult.name
                )
                await previewRoutes(to: waypoint, searchResultRecord: searchResult)
            }
        } else {
            Log.info("CPRouteChoice should contain `NavigationRoutes` struct.", category: .carPlay)
        }
    }

    @MainActor
    private func startTrip(
        mapTemplate: CPMapTemplate,
        trip: CPTrip,
        navigationRoutes: NavigationRoutes
    ) {
        guard let interfaceController, let carPlayMapViewController, let carWindow else {
            return
        }
        // Allow the new navigation session to perform its post-navigation cleanup once.
        hasStartedNavigationCleanup = false
        clearMapAnnotations()

        mapTemplate.hideTripPreviews()
        // Starting the trip consumes the preview session. Its template is popped below and must not be reused by
        // a later preview or torn down by a later cancellation.
        cancelPendingPreviewRequest()
        previewState = .inactive
        routes = nil
        setCurrentActivity(.navigating)

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
                // The navigation controller can appear while transient controls are already visible. Carry over the
                // vehicle-specific baseline learned while browsing so that initial controls are not treated as settled
                // safe-area insets.
                carPlayNavigationViewController.safeAreaInsetsBaseline =
                    carPlayMapViewController.safeAreaInsetsBaseline
                carPlayNavigationViewController.configureMap(
                    mapOptions: mapOptions(for: carWindow),
                    usesCompactMapOverlays: usesCompactMapOverlays(for: carWindow)
                )
                carPlayNavigationViewController.hidesSpeedLimitViewWithMapControls =
                    hidesSpeedLimitViewWithMapControls
                carPlayNavigationViewController.startNavigationSession(for: trip)
                carPlayNavigationViewController.delegate = self
                carPlayNavigationViewController.modalPresentationStyle = .fullScreen
                self.carPlayNavigationViewController = carPlayNavigationViewController

                carPlayNavigationViewController.loadViewIfNeeded()
                delegate?.carPlayManager(self, willPresent: carPlayNavigationViewController)
                updateNavigationButtons(for: navigationMapTemplate)

                subscribeForCameraStateNotifications()

                carPlayMapViewController.present(carPlayNavigationViewController, animated: true) { [weak self] in
                    guard let self else { return }
                    delegate?.carPlayManager(self, didPresent: carPlayNavigationViewController)
                }

                removeRoutesFromBrowsingMap()
                // Keep the free-drive camera idle while its map is covered by active guidance. It is positioned
                // at the latest following target immediately before guidance is dismissed.
                carPlayMapViewController.navigationMapView.navigationCamera.stop()
            }
        }
    }

    func navigationMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        let currentActivity: CarPlayActivity = .navigating
        mapTemplate.currentActivity = currentActivity

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
        } else if let searchResult = routeChoice.searchResultRecord {
            carPlayMapViewController?.showSearchResultsAnnotations(
                with: fetchedSearchResults,
                selectedResult: searchResult
            )
        } else {
            Log.info("CPRouteChoice should contain `NavigationRoutes` or `SearchResultRecord`.", category: .carPlay)
        }
    }

    @MainActor
    @_spi(MapboxCarPlaySearchInternal)
    public func clearMapAnnotations() {
        fetchedSearchResults = []
        carPlayMapViewController?.removeSearchResultsAnnotations()
    }

    private func localized(measurement: Measurement<UnitLength>) -> Measurement<UnitLength> {
        measurement.localized(into: locale, unitMeasurementSystem: unitMeasurementSystem)
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
        let measurement = Measurement(distance: route.distance)
        let estimates = CPTravelEstimates(
            distanceRemaining: localized(measurement: measurement),
            timeRemaining: route.expectedTravelTime
        )
        mapTemplate.updateEstimates(estimates, for: trip)

        let navigationMapView = carPlayMapViewController.navigationMapView
        navigationMapView.showcase(
            routes,
            routeAnnotationKinds: [],
            animated: true,
            duration: CarPlayUtilities.previewCameraAnimationDuration
        )
        self.routes = routes
        delegate?.carPlayManager(self, selectedPreviewFor: trip, using: routeChoice)
    }

    @MainActor
    public func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        if let carPlayNavigationViewController {
            carPlayMapViewController?.setFreeDriveCamera(animated: false)
            carPlayNavigationViewController.dismiss(animated: true) { [weak self] in
                MainActor.assumingIsolated {
                    self?.completeNavigationCleanup(byCanceling: false)
                }
            }
        } else {
            completeNavigationCleanup(byCanceling: false)
        }
    }

    @MainActor
    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        // Whenever panning starts - stop any navigation camera updates.
        activeNavigationMapView?.navigationCamera.stop()
        updateWayNameViewVisibility(cameraState: .idle)
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
        mapTemplate.currentActivity = currentActivity
        setCurrentActivity(currentActivity)

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

        delegate?.carPlayManager(self, didShowPanningInterface: mapTemplate)
    }

    public func mapTemplateWillDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        Task { @MainActor in
            delegate?.carPlayManager(self, willDismissPanningInterface: mapTemplate)
        }
    }

    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        Task { @MainActor in
            guard let currentActivity = mapTemplate.previousActivity else { return }
            mapTemplate.currentActivity = currentActivity
            setCurrentActivity(currentActivity)

            updateNavigationButtons(for: mapTemplate)
            delegate?.carPlayManager(self, didDismissPanningInterface: mapTemplate)
        }
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

    @MainActor
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
        MainActor.assumingIsolated {
            delegate?.carPlayManagerWillEndNavigation(self, byCanceling: canceled)
            carPlayMapViewController?.setFreeDriveCamera(animated: false)
        }
    }

    public func carPlayNavigationViewControllerDidDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    ) {
        MainActor.assumingIsolated {
            completeNavigationCleanup(byCanceling: canceled)
        }
    }

    @MainActor
    private func completeNavigationCleanup(byCanceling canceled: Bool) {
        guard let interfaceController, !hasStartedNavigationCleanup else {
            return
        }
        hasStartedNavigationCleanup = true

        // Dismiss the template for previous arrival UI when exit the navigation.
        interfaceController.dismissTemplate(animated: true, completion: nil)
        // Unset existing main map template (fixes an issue with the buttons)
        mainMapTemplate = nil
        carPlayNavigationViewController = nil
        removeRoutesFromBrowsingMap()

        // Restore the browsing camera before rebuilding camera-state-dependent controls and subscriptions.
        carPlayMapViewController?.navigationMapView.update(navigationCameraState: .following)

        // Then (re-)create and assign new map template
        let mapTemplate = browseAndFreeDriveMapTemplate()
        mainMapTemplate = mapTemplate

        setRootTemplate(
            interfaceController: interfaceController,
            rootTemplate: mapTemplate,
            animated: true
        ) { _, _ in
            MainActor.assumingIsolated { [weak self] in
                guard let self else { return }
                subscribeForCameraStateNotifications()

                delegate?.carPlayManagerDidEndNavigation(self)
                delegate?.carPlayManagerDidEndNavigation(self, byCanceling: canceled)
            }
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

    @_spi(MapboxCarPlayInternal)
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

// MARK: CarPlayManager Constants

extension CarPlayManager {
    static let currentActivityKey = "com.mapbox.navigation.currentActivity"
    static let previousActivityKey = "com.mapbox.navigation.previousActivity"
}

extension NavigationRoute {
    var directionsOptions: DirectionsOptions {
        switch requestOptions {
        case .route(let options):
            options
        case .match(let options):
            options
        }
    }
}
