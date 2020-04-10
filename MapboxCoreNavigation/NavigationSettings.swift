import Foundation

/**
 A wrapper for the `UserDefaults` class for navigation-specific settings.
 
 Properties are prefixed before they are stored in `UserDefaults.standard`.
 
 To specify criteria when calculating routes, use the `NavigationRouteOptions` class. To customize the user experience during a particular turn-by-turn navigation session, use the `NavigationOptions` class when initializing a `NavigationViewController`.
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
     - note: Anything but `kilometer` and `mile` will fall back to the default measurement for the current locale.
        Meters and feets will be used when the presented distances are small enough. See `DistanceFormatter` for more information.
     */
    public dynamic var distanceUnit : LengthFormatter.Unit = Locale.current.usesMetric ? .kilometer : .mile {
        didSet {
            notifyChanged(property: .distanceUnit, value: distanceUnit.rawValue)
        }
    }
    
    var usesMetric: Bool {
        get {
            switch distanceUnit {
            case .kilometer:
                return true
            case .mile:
                return false
            default:
                return Locale.current.usesMetric
            }
        }
    }
    
    /**
     The shared navigation settings object that affects the entire application.
     */
    public static let shared = NavigationSettings()
    
    /// Returns a reflection of this class excluding the `properties` variable.
    lazy var properties: [Mirror.Child] = {
        let properties = Mirror(reflecting: self).children
        return properties.filter({ (child) -> Bool in
            if let label = child.label {
                return label != "properties.storage" && label != "$__lazy_storage_$_properties"
            }
            return false
        })
    }()
    
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
