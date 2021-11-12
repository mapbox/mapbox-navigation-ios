import Foundation
import MapboxDirections

/**
 Global settings that are used across the SDK for altering navigation behavior.

 Some properties listed in `StoredProperty` are stored in `UserDefaults.standard`.

 To specify criteria when calculating routes, use the `NavigationRouteOptions` class.

 To customize the user experience during a particular turn-by-turn navigation session, use the `NavigationOptions` class
 when initializing a `NavigationViewController`.

 To customize some global defaults use `NavigationSettings.initialize(directions:tileStoreConfiguration:)` method.
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

    private struct State {
        static var `default`: State {
            .init(directions: .shared, tileStoreConfiguration: .default)
        }

        var directions: Directions
        var tileStoreConfiguration: TileStoreConfiguration
    }

    /// Protects access to `_state`.
    private let lock: NSLock = .init()

    private var _state: State?

    private var state: State {
        lock.lock(); defer {
            lock.unlock()
        }
        if let state = _state {
            return state
        }
        else {
            let defaultState: State = .default
            _state = defaultState
            return defaultState
        }
    }
    /**
     Default `Directions` instance. By default, `Directions.shared` is used.

     You can override this property by using `NavigationSettings.initialize(directions:tileStoreConfiguration:)` method.
     */
    public var directions: Directions {
        state.directions
    }

    /**
     Global `TileStoreConfiguration` instance.

     You can override this property by using `NavigationSettings.initialize(directions:tileStoreConfiguration:)` method.
     */
    public var tileStoreConfiguration: TileStoreConfiguration {
        state.tileStoreConfiguration
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
     */
    public func initialize(directions: Directions,
                           tileStoreConfiguration: TileStoreConfiguration) {
        lock.lock(); defer {
            lock.unlock()
        }
        if _state != nil {
            print("Warning: Using NavigationSettings.initialize(directions:tileStoreConfiguration:) after corresponding variables was initialized. Possible reasons: Initialize called more than once, or the following properties was accessed before initialization: `tileStoreConfiguration`, `directions`. This might result in an undefined behaviour. ")
        }
        _state = .init(directions: directions, tileStoreConfiguration: tileStoreConfiguration)
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
