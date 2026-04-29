import Foundation
import MapboxNavigationCore

/// Customization options for the turn-by-turn navigation user experience in a ``NavigationViewController``.
///
/// A navigation options object is where you place customized components that the navigation view controller uses during
/// its lifetime, such as styles or voice controllers.
///
/// - Note: ``NavigationOptions`` is designed to be used with the ``NavigationViewController`` class to customize the
/// user experience. To specify criteria when calculating routes, use the `NavigationRouteOptions` class. To modify
/// user preferences that persist across navigation sessions, use the `CoreConfig` class.
open class NavigationOptions {
    // MARK: Customizing Visualization

    /// The styles that the view controller’s internal ``StyleManager`` object can select from for display.
    ///
    /// If this property is set to `nil`, a ``StandardDayStyle`` and a ``StandardNightStyle`` are created to be used as
    /// the view controller’s styles. This property is set to `nil` by default.
    open var styles: [Style]?

    /// The view controller to embed into the top section of the UI.
    ///
    /// If this property is set to `nil`, a ``TopBannerViewController`` is created and embedded in the UI. This property
    /// is set to `nil` by default.
    open var topBanner: ContainerViewController?

    /// The view controller to embed into the bottom section of the UI.
    ///
    /// If this property is set to `nil`, a ``BottomBannerViewController`` is created and embedded in the UI. This
    /// property is set to `nil` by default.
    open var bottomBanner: ContainerViewController?

    /// Custom `NavigationMapView` instance to be embedded in navigation UI.
    ///
    /// If set to `nil`, a default `NavigationMapView` instance will be created. When a custom instance is set,
    /// ``NavigationView`` will update its delegate and camera's `viewportDatasource` to function correctly. You may
    /// want to use this property for customization or optimization purposes.
    open var navigationMapView: NavigationMapView?

    // MARK: Configuring the Data Services and Processing

    /// The navigation service that manages navigation along the route.
    open var mapboxNavigation: MapboxNavigation

    /// The events manager, used to send user feedback.
    open var eventsManager: NavigationEventsManager

    /// The voice controller that manages the delivery of voice instructions during navigation.
    open var voiceController: RouteVoiceController

    /// Configuration for predictive caching.
    ///
    /// This option controls how the map view will try to proactively fetch data related to the route. A `nil` value
    /// disables the feature.
    open var predictiveCacheManager: PredictiveCacheManager?

    /// A Required initializator.
    ///
    /// You should never call it. Use ``init(mapboxNavigation:voiceController:eventsManager:styles:topBanner:bottomBanner:predictiveCacheManager:navigationMapView:)``
    /// instead.
    @MainActor
    public required init() {
        let provider = MapboxNavigationProvider(coreConfig: .init())
        self.mapboxNavigation = provider.mapboxNavigation
        self.voiceController = provider.routeVoiceController
        self.eventsManager = provider.eventsManager()
    }

    /// Initializes an object that configures a ``NavigationViewController``.
    /// - Parameters:
    ///   - mapboxNavigation: The navigation service that manages navigation along the route.
    ///   - voiceController: The voice controller that vocalizes spoken instructions along the route at the appropriate
    /// times.
    ///   - eventsManager: The events manager, used to send user feedback.
    ///   - styles: The user interface styles that are available for display.
    ///   - topBanner: The container view controller that presents the top banner.
    ///   - bottomBanner: The container view controller that presents the bottom banner.
    ///   - predictiveCacheManager: The predictive cache manager.
    ///   - navigationMapView: Custom `NavigationMapView` instance to supersede the default one.
    public init(
        mapboxNavigation: MapboxNavigation,
        voiceController: RouteVoiceController,
        eventsManager: NavigationEventsManager,
        styles: [Style]? = nil,
        topBanner: ContainerViewController? = nil,
        bottomBanner: ContainerViewController? = nil,
        predictiveCacheManager: PredictiveCacheManager? = nil,
        navigationMapView: NavigationMapView? = nil
    ) {
        self.mapboxNavigation = mapboxNavigation
        self.eventsManager = eventsManager
        self.styles = styles
        self.voiceController = voiceController
        self.topBanner = topBanner
        self.bottomBanner = bottomBanner
        self.predictiveCacheManager = predictiveCacheManager
        self.navigationMapView = navigationMapView
    }
}
