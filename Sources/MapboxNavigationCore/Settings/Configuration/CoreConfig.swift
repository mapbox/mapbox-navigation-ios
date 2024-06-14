import CoreLocation
import Foundation
import MapboxCommon
import MapboxDirections

/// Mutable Core SDK configuration.
public struct CoreConfig: Equatable {
    /// Describes the context under which a manual switching between legs is happening.
    public struct MultiLegAdvanceContext: Sendable, Equatable {
        /// The leg index of a destination user has arrived to.
        public let arrivedLegIndex: Int
    }

    /// Allows to manually or automatically switch legs on a multileg route.
    public typealias MultilegAdvanceMode = ApprovalModeAsync<MultiLegAdvanceContext>

    /// SDK Credentials.
    public let credentials: NavigationCoreApiConfiguration

    /// Configures route request.
    public var routeRequestConfig: RouteRequestConfig

    /// Routing Configuration.
    public var routingConfig: RoutingConfig

    /// Custom metadata that can be used with events in the telemetry pipeline.
    public let telemetryAppMetadata: TelemetryAppMetadata?

    /// Sources for location and route drive simulation. Defaults to ``LocationSource/live``.
    public var locationSource: LocationSource

    /// Logging level for Mapbox SDKs. Defaults to `.warning`.
    public var logLevel: MapboxCommon.LoggingLevel

    /// A Boolean value that indicates whether a copilot recording is enabled. Defaults to `false`.
    public let copilotEnabled: Bool

    /// Configures default unit of measurement.
    public var unitOfMeasurement: UnitOfMeasurement = .auto

    /// A `Locale` that is used for guidance instruction and other localization features.
    public var locale: Locale = .nationalizedCurrent

    /// A Boolean value that indicates whether a background location tracking is enabled. Defaults to `true`.
    public let disableBackgroundTrackingLocation: Bool

    /// A Boolean value that indicates whether a sensor data is utilized. Defaults to `false`.
    public let utilizeSensorData: Bool

    /// Defines approximate navigator prediction between location ticks.
    /// Due to discrete location updates, Navigator always operates data "in the past" so it has to make prediction
    /// about user's current real position. This interval controls how far ahead Navigator will try to predict user
    /// location.
    public let navigatorPredictionInterval: TimeInterval?

    /// Congestion level configuration.
    public var congestionConfig: CongestionRangesConfiguration

    /// Configuration for navigation history recording.
    public let historyRecordingConfig: HistoryRecordingConfig?

    /// Predictive cache configuration.
    public var predictiveCacheConfig: PredictiveCacheConfig?

    /// Electronic Horizon Configuration.
    public var electronicHorizonConfig: ElectronicHorizonConfig?

    /// Electronic Horizon incidents configuration.
    public let liveIncidentsConfig: IncidentsConfig?

    /// Multileg advancing mode.
    public var multilegAdvancing: MultilegAdvanceMode

    /// Tiles version.
    public let tilesVersion: String

    /// Options for configuring how map and navigation tiles are stored on the device.
    public let tilestoreConfig: TileStoreConfiguration

    /// Configuration for Text-To-Speech engine used.
    public var ttsConfig: TTSConfig

    /// Billing handler overriding for testing purposes.
    var __customBillingHandler: BillingHandlerProvider? = nil

    /// Events manager overriding for testing purposes.
    var __customEventsManager: EventsManagerProvider? = nil

    /// Routing provider overriding for testing purposes.
    var __customRoutingProvider: CustomRoutingProvider? = nil

    /// Mutable Routing configuration.
    public struct RouteRequestConfig: Equatable, Sendable {
        /// A string specifying the primary mode of transportation for the routes.
        /// `ProfileIdentifier.automobileAvoidingTraffic` is used by default.
        public let profileIdentifier: ProfileIdentifier

        /// The route classes that the calculated routes will avoid.
        public var roadClassesToAvoid: RoadClasses

        /// The route classes that the calculated routes will allow.
        /// This property has no effect unless the profile identifier is set to `ProfileIdentifier.automobile` or
        /// `ProfileIdentifier.automobileAvoidingTraffic`.
        public var roadClassesToAllow: RoadClasses

        ///  A Boolean value that indicates whether a returned route may require a point U-turn at an intermediate
        /// waypoint.
        ///
        ///  If the value of this property is `true`, a returned route may require an immediate U-turn at an
        /// intermediate
        /// waypoint. At an intermediate waypoint, if the value of this property is `false`, each returned route may
        /// continue straight ahead or turn to either side but may not U-turn. This property has no effect if only two
        /// waypoints are specified.
        ///
        ///  Set this property to `true` if you expect the user to traverse each leg of the trip separately. For
        /// example, it
        /// would be quite easy for the user to effectively “U-turn” at a waypoint if the user first parks the car and
        /// patronizes a restaurant there before embarking on the next leg of the trip. Set this property to `false` if
        /// you
        /// expect the user to proceed to the next waypoint immediately upon arrival. For example, if the user only
        /// needs to
        /// drop off a passenger or package at the waypoint before continuing, it would be inconvenient to perform a
        /// U-turn
        /// at that location.
        ///  The default value of this property is `false.
        public var allowsUTurnAtWaypoint: Bool

        /// URL query items to be parsed and applied as configuration to the route request.
        public var customQueryParameters: [URLQueryItem]?

        /// Initializes a new `CoreConfig` object.
        /// - Parameters:
        ///   - profileIdentifier: A string specifying the primary mode of transportation for the routes.
        ///   - roadClassesToAvoid: The route classes that the calculated routes will avoid.
        ///   - roadClassesToAllow: The route classes that the calculated routes will allow.
        ///   - allowsUTurnAtWaypoint: A Boolean value that indicates whether a returned route may require a point
        ///   - customQueryParameters: URL query items to be parsed and applied as configuration to the route request.
        /// U-turn at an intermediate waypoint.
        public init(
            profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic,
            roadClassesToAvoid: RoadClasses = [],
            roadClassesToAllow: RoadClasses = [],
            allowsUTurnAtWaypoint: Bool = false,
            customQueryParameters: [URLQueryItem]? = nil
        ) {
            self.profileIdentifier = profileIdentifier
            self.roadClassesToAvoid = roadClassesToAvoid
            self.roadClassesToAllow = roadClassesToAllow
            self.allowsUTurnAtWaypoint = allowsUTurnAtWaypoint
            self.customQueryParameters = customQueryParameters
        }
    }

    /// Creates a new ``CoreConfig`` instance.
    /// - Parameters:
    ///   - credentials: SDK Credentials.
    ///   - routeRequestConfig: Route requiest configuration
    ///   - routingConfig: Routing Configuration.
    ///   - telemetryAppMetadata: Custom metadata that can be used with events in the telemetry pipeline.
    ///   - logLevel: Logging level for Mapbox SDKs.
    ///   - isSimulationEnabled: A Boolean value that indicates whether a route simulation is enabled.
    ///   - copilotEnabled: A Boolean value that indicates whether a copilot recording is enabled.
    ///   - unitOfMeasurement: Configures default unit of measurement.
    ///   - locale: A `Locale` that is used for guidance instruction and other localization features.
    ///   - disableBackgroundTrackingLocation: Indicates if a background location tracking is enabled.
    ///   - utilizeSensorData: A Boolean value that indicates whether a sensor data is utilized.
    ///   - navigatorPredictionInterval: Defines approximate navigator prediction between location ticks.
    ///   - congestionConfig: Congestion level configuration.
    ///   - historyRecordingConfig: Configuration for navigation history recording.
    ///   - predictiveCacheConfig: Predictive cache configuration.
    ///   - electronicHorizonConfig: Electronic Horizon Configuration.
    ///   - liveIncidentsConfig: Electronic Horizon incidents configuration.
    ///   - multilegAdvancing: Multileg advancing mode.
    ///   - tilesVersion: Tiles version.
    ///   - tilestoreConfig: Options for configuring how map and navigation tiles are stored on the device.
    ///   - ttsConfig: Configuration for Text-To-Speech engine used.
    public init(
        credentials: NavigationCoreApiConfiguration = .init(),
        routeRequestConfig: RouteRequestConfig = .init(),
        routingConfig: RoutingConfig = .init(),
        telemetryAppMetadata: TelemetryAppMetadata? = nil,
        logLevel: MapboxCommon.LoggingLevel = .warning,
        locationSource: LocationSource = .live,
        copilotEnabled: Bool = false,
        unitOfMeasurement: UnitOfMeasurement = .auto,
        locale: Locale = .nationalizedCurrent,
        disableBackgroundTrackingLocation: Bool = true,
        utilizeSensorData: Bool = false,
        navigatorPredictionInterval: TimeInterval? = nil,
        congestionConfig: CongestionRangesConfiguration = .default,
        historyRecordingConfig: HistoryRecordingConfig? = nil,
        predictiveCacheConfig: PredictiveCacheConfig? = PredictiveCacheConfig(),
        electronicHorizonConfig: ElectronicHorizonConfig? = nil,
        liveIncidentsConfig: IncidentsConfig? = nil,
        multilegAdvancing: MultilegAdvanceMode = .automatically,
        tilesVersion: String = "",
        tilestoreConfig: TileStoreConfiguration = .default,
        ttsConfig: TTSConfig = .default
    ) {
        self.credentials = credentials
        self.routeRequestConfig = routeRequestConfig
        self.telemetryAppMetadata = telemetryAppMetadata
        self.logLevel = logLevel
        self.locationSource = locationSource
        self.copilotEnabled = copilotEnabled
        self.unitOfMeasurement = unitOfMeasurement
        self.locale = locale
        self.disableBackgroundTrackingLocation = disableBackgroundTrackingLocation
        self.utilizeSensorData = utilizeSensorData
        self.navigatorPredictionInterval = navigatorPredictionInterval
        self.congestionConfig = congestionConfig
        self.historyRecordingConfig = historyRecordingConfig
        self.predictiveCacheConfig = predictiveCacheConfig
        self.electronicHorizonConfig = electronicHorizonConfig
        self.liveIncidentsConfig = liveIncidentsConfig
        self.multilegAdvancing = multilegAdvancing
        self.routingConfig = routingConfig
        self.tilesVersion = tilesVersion
        self.tilestoreConfig = tilestoreConfig
        self.ttsConfig = ttsConfig
    }
}
