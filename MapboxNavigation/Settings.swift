import Foundation

extension UserDefaults {
    fileprivate func registerNavigationDefaults() {
        register(defaults: [NavigationSettingsKey.muted.rawValue: false])
    }
}

enum NavigationSettingsKey: String {
    case muted = "muted"
}

struct NavigationSettings {
    
    var defaults: UserDefaults
    
    static var shared: NavigationSettings = {
        let defaults = UserDefaults(suiteName: "com.mapbox.MapboxNavigation")
        defaults?.registerNavigationDefaults()
        return NavigationSettings(defaults: defaults!)
    }()
    
    public var muted: Bool {
        get {
            return defaults.bool(forKey: NavigationSettingsKey.muted.rawValue) 
        }
        set {
            defaults.set(newValue, forKey: NavigationSettingsKey.muted.rawValue)
        }
    }
}
