import Foundation
import MapboxCommon
import MapboxDirections

/// Defines source of routing engine (online or offline) to be used for requests.
public typealias RoutingProviderSource = MapboxRoutingProvider.Source

/// Configures Navigator status polling.
public struct StatusUpdatingSettings {
    /**
     If new location is not provided during `updatingPatience` - status will be polled unconditionally.
     
     If `nil` - default value will be used.
     */
    public var updatingPatience: TimeInterval?
    /**
     Interval of unconditional status polling.
     
     If `nil` - default value will be used.
     */
    public var updatingInterval: TimeInterval?

    /**
     Creates new `StatusUpdatingSettings`.
     
     - parameter updatingPatience: patience time before unconditional status polling.
     - parameter updatingInterval: unconditional polling interval.
     */
    public init(updatingPatience: TimeInterval? = nil, updatingInterval: TimeInterval? = nil) {
        self.updatingPatience = updatingPatience
        self.updatingInterval = updatingInterval
    }
}

/**
 Global settings that are used across the SDK for altering navigation behavior.

 Some properties listed in `StoredProperty` are stored in `UserDefaults.standard`.

 To specify criteria when calculating routes, use the `NavigationRouteOptions` class.

 To customize the user experience during a particular turn-by-turn navigation session, use the `NavigationOptions` class
 when initializing a `NavigationViewController`.

 To customize some global defaults use `NavigationSettings.initialize(with:)` method.
 */
public class NavigationSettings {

    public enum StoredProperty: CaseIterable {
        case voiceVolume, voiceMuted, distanceUnit

        public var key: String {
            switch self {
            case .voiceVolume:
                return "voiceVolume"
            case .voiceMuted:
                return "voiceMuted"
            case .distanceUnit:
                return "distanceUnit"
            }
        }
    }

    /// All the values that you can setup NavigationSettings with.
    public struct Values {
        let directions: Directions
        let tileStoreConfiguration: TileStoreConfiguration
        let routingProviderSource: RoutingProviderSource
        let alternativeRouteDetectionStrategy: AlternativeRouteDetectionStrategy?
        let utilizeSensorData: Bool
        let navigatorPredictionInterval: TimeInterval?
        let liveIncidentsOptions: IncidentsOptions?
        let statusUpdatingSettings: StatusUpdatingSettings?
        let logLevel: MapboxCommon.LoggingLevel

        /**
         Creates new `Values` instance.

         - parameter directions: Default `Directions` instance. Some types allow you to customize the directions instance and
     fall back to the `NavigationSettings.directions` by default.
         - parameter tileStoreConfiguration: Options for configuring how map and navigation tiles are stored on the device. See
     `TileStoreConfiguration` for more details.
         - parameter routingProviderSource: Configures the type of routing to be used by various SDK objects when providing route calculations. Use this value to configure usage of online vs. offline data for routing.
         - parameter alternativeRouteDetectionStrategy: Configures how `AlternativeRoute`s will be detected during navigation process.
         - parameter utilizeSensorData: Enables using sensors data to improve positioning.
         - parameter navigatorPredictionInterval: Defines approximate navigator prediction between location ticks.
         - parameter liveIncidentsOptions: Configures Electronic Horizon live incidents.
         - parameter statusUpdatingSettings: Configures how navigator status is polled.
         - parameter logLevel: Logging level for Mapbox SDKs.
         */
        public init(directions: Directions = .shared,
                    tileStoreConfiguration: TileStoreConfiguration = .default,
                    routingProviderSource: RoutingProviderSource = .hybrid,
                    alternativeRouteDetectionStrategy: AlternativeRouteDetectionStrategy? = .init(),
                    utilizeSensorData: Bool = false,
                    navigatorPredictionInterval: TimeInterval? = nil,
                    liveIncidentsOptions: IncidentsOptions? = nil,
                    statusUpdatingSettings: StatusUpdatingSettings? = nil,
                    logLevel: MapboxCommon.LoggingLevel = .info) {
            self.directions = directions
            self.tileStoreConfiguration = tileStoreConfiguration
            self.routingProviderSource = routingProviderSource
            self.alternativeRouteDetectionStrategy = alternativeRouteDetectionStrategy
            self.utilizeSensorData = utilizeSensorData
            self.navigatorPredictionInterval = navigatorPredictionInterval
            self.liveIncidentsOptions = liveIncidentsOptions
            self.statusUpdatingSettings = statusUpdatingSettings
            self.logLevel = logLevel
        }
    }

    /// Protects access to `_values`.
    private let lock: NSLock = .init()

    private var _values: Values? {
        didSet {
            guard let _values = _values else { return }

            let loggingLevel = NSNumber(value: _values.logLevel.rawValue)
            LogConfiguration.setLoggingLevelForUpTo(loggingLevel)
        }
    }

    private var values: Values {
        lock.lock(); defer {
            lock.unlock()
        }
        if let values = _values {
            return values
        }
        else {
            let defaultState: Values = .init()
            _values = defaultState
            return defaultState
        }
    }
    /**
     Default `Directions` instance. By default, `Directions.shared` is used.

     You can override this property by using `NavigationSettings.initialize(with:)` method.
     */
    public var directions: Directions {
        values.directions
    }

    /**
     Global `TileStoreConfiguration` instance.

     You can override this property by using `NavigationSettings.initialize(with:)` method.
     */
    public var tileStoreConfiguration: TileStoreConfiguration {
        values.tileStoreConfiguration
    }

    /**
     Type of routing to be used by various SDK objects when providing route calculations. Use this value to configure usage of online vs. offline data for routing.

     You can override this property by using `NavigationSettings.initialize(with:)` method.
     */
    public var routingProviderSource: RoutingProviderSource {
        values.routingProviderSource
    }

    /**
     Configuration on how `AlternativeRoute`s will be detected during navigation process.
     
     You can override this property by using `NavigationSettings.initialize(with:)` method.
     
     If set to `nil`, the detection is turned off.
     */
    public var alternativeRouteDetectionStrategy: AlternativeRouteDetectionStrategy? {
        values.alternativeRouteDetectionStrategy
    }

    /**
     Enables analyzing data from sensors for better location prediction in case of a weak GPS signal, for example in tunnel.
     
     Usage of sensors can increase battery consumption. Disabled by default.
     
     - important: Don't enable sensors if you emulate location updates. The SDK ignores location updates which don't match data from sensors.
     */
    public var utilizeSensorData: Bool {
        values.utilizeSensorData
    }

    /**
     Defines approximate navigator prediction between location ticks.
     
     Due to discrete location updates, Navigator always operates data "in the past" so it has to make prediction about user's current real position. This interval controls how far ahead Navigator will try to predict user location.
     
     If not specified (`nilled`), default value will be used.
     
     You can override this property by using `NavigationSettings.initialize(with:)` method.
     */
    public var navigatorPredictionInterval: TimeInterval? {
        values.navigatorPredictionInterval
    }

    /**
     Configuration on how live incidents on a most probable path are detected.
     
     You can override this property by using `NavigationSettings.initialize(with:)` method.
     
     If set to `nil`, live incidents are turned off (by default).
     */
    public var liveIncidentsOptions: IncidentsOptions? {
        values.liveIncidentsOptions
    }

    /**
     Configuration on how navigator status is polled.
     
     You can override this property by using `NavigationSettings.initialize(with:)` method.
     
     If set to `nil`, default settings will be applied
     */
    public var statusUpdatingSettings: StatusUpdatingSettings? {
        values.statusUpdatingSettings
    }

    /**
     Initializes the settings with custom instances of globally used types.

     If you don't provide custom values, they will be initialized with the defaults.

     - important: If you want to use this method, it should be the first method you use from Navigation SDK.
     Not doing so will lead to undefined behavior.

     - Parameters:
       - directions: Default `Directions` instance. Some types allow you to customize the directions instance and
     fall back to the `NavigationSettings.directions` by default.
       - tileStoreConfiguration: Options for configuring how map and navigation tiles are stored on the device. See
     `TileStoreConfiguration` for more details.
       - routingProviderSource: Configures the type of routing to be used by various SDK objects when providing route calculations. Use this value to configure usage of onlive vs. offline data for routing.
       - alternativeRouteDetectionStrategy: Configures how `AlternativeRoute`s will be detected during navigation process.
       - utilizeSensorData: Enables using sensors data to improve positioning.
       - navigatorPredictionInterval: Defines approximate navigator prediction between location ticks.
       - liveIncidentsOptions: Configures Electronic Horizon live incidents.
       - statusUpdatingSettings: Configures how navigator status is polled.
     */
    @available(*, deprecated, renamed: "initialize(with:)")
    public func initialize(directions: Directions,
                           tileStoreConfiguration: TileStoreConfiguration,
                           routingProviderSource: RoutingProviderSource = .hybrid,
                           alternativeRouteDetectionStrategy: AlternativeRouteDetectionStrategy? = .init(),
                           utilizeSensorData: Bool = false,
                           navigatorPredictionInterval: TimeInterval? = nil,
                           liveIncidentsOptions: IncidentsOptions? = nil,
                           statusUpdatingSettings: StatusUpdatingSettings? = nil) {
        self.initialize(
            with: .init(
                directions: directions,
                tileStoreConfiguration: tileStoreConfiguration,
                routingProviderSource: routingProviderSource,
                alternativeRouteDetectionStrategy: alternativeRouteDetectionStrategy,
                utilizeSensorData: utilizeSensorData,
                navigatorPredictionInterval: navigatorPredictionInterval,
                liveIncidentsOptions: liveIncidentsOptions,
                statusUpdatingSettings: statusUpdatingSettings
            )
        )
    }

    /**
     Initializes the settings with custom instances of globally used types.

     If you don't provide custom values, they will be initialized with the defaults.

     - important: If you want to use this method, it should be the first method you use from Navigation SDK.
     Not doing so will lead to undefined behavior.

     - Parameters:
       - values: Values to be used for global settings.
     */
    public func initialize(with values: Values) {
        lock.lock(); defer {
            lock.unlock()
        }
        if _values != nil {
            Log.warning("Warning: Using NavigationSettings.initialize(with:) after corresponding variables was initialized. Possible reasons: Initialize called more than once, or the following properties was accessed before initialization: `tileStoreConfiguration`, `directions`, `routingProviderSource`, `alternativeRouteDetectionStrategy`, `utilizeSensorData`, `navigatorPredictionInterval`, `liveIncidentsOptions`, `statusUpdatingSettings`. This might result in an undefined behaviour.", category: .settings)
        }
        _values = values
    }

    /**
     The volume that the voice controller will use.
     
     This volume is relative to the system’s volume where 1.0 is same volume as the system.
     */
    public dynamic var voiceVolume: Float = 1.0 {
        didSet {
            notifyChanged(property: .voiceVolume, value: voiceVolume)
        }
    }

    /**
     Specifies whether to mute the voice controller or not.
     */
    public dynamic var voiceMuted : Bool = false {
        didSet {
            notifyChanged(property: .voiceMuted, value: voiceMuted)
        }
    }

    /**
     Specifies the preferred distance measurement unit.
     Meters and feet will be used when the presented distances are small enough. See `DistanceFormatter` for more information.
     */
    public dynamic var distanceUnit : LengthFormatter.Unit = Locale.current.measuresDistancesInMetricUnits ? .kilometer : .mile {
        didSet {
            notifyChanged(property: .distanceUnit, value: distanceUnit.rawValue)
        }
    }

    /**
     The shared navigation settings object that affects the entire application.
     */
    public static let shared: NavigationSettings = .init()

    private func notifyChanged(property: StoredProperty, value: Any) {
        UserDefaults.standard.set(value, forKey: property.key.prefixed)
        NotificationCenter.default.post(name: .navigationSettingsDidChange,
                                        object: nil,
                                        userInfo: [property.key: value])
    }

    private func setupFromDefaults() {
        for property in StoredProperty.allCases {

            guard let val = UserDefaults.standard.object(forKey: property.key.prefixed) else { continue }
            switch property {
            case .voiceVolume:
                if let volume = val as? Float {
                    voiceVolume = volume
                }
            case .voiceMuted:
                if let muted = val as? Bool {
                    voiceMuted = muted
                }
            case .distanceUnit:
                if let value = val as? Int, let unit = LengthFormatter.Unit(rawValue: value) {
                    distanceUnit = unit
                }
            }
        }
    }

    init() {
        setupFromDefaults()
    }
}

extension String {
    fileprivate var prefixed: String {
        return "MB" + self
    }
}

extension MeasurementSystem {
    /// :nodoc: Converts `LengthFormatter.Unit` into `MapboxDirections.MeasurementSystem`.
    public init(_ lengthUnit: LengthFormatter.Unit) {
        let metricUnits: [LengthFormatter.Unit] = [.kilometer, .centimeter, .meter, .millimeter]
        self = metricUnits.contains(lengthUnit) ? .metric : .imperial
    }
}

extension LengthFormatter.Unit {
    /// :nodoc: Converts `MapboxDirections.MeasurementSystem` into `LengthFormatter.Unit`.
    public init(_ measurementSystem: MeasurementSystem) {
        self = measurementSystem == .metric ? .kilometer : .mile
    }
}
