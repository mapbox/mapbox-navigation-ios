import Foundation

extension UserDefaults {
    fileprivate func registerNavigationDefaults() {
        register(defaults: [NavigationSettingsKey.voiceVolume.rawValue: false])
    }
}

enum NavigationSettingsKey: String {
    case voiceVolume = "voiceVolume"
}

struct NavigationSettings {
    
    var defaults: UserDefaults
    
    static var shared: NavigationSettings = {
        let defaults = UserDefaults(suiteName: "com.mapbox.MapboxNavigation")
        defaults?.registerNavigationDefaults()
        return NavigationSettings(defaults: defaults!)
    }()
    
    public var voiceVolume: Float {
        get {
            return defaults.float(forKey: NavigationSettingsKey.voiceVolume.rawValue)
        }
        set {
            defaults.set(newValue, forKey: NavigationSettingsKey.voiceVolume.rawValue)
        }
    }
}
