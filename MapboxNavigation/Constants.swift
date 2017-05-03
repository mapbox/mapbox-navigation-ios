import Foundation
import Mapbox

fileprivate extension UserDefaults {
    func registerNavigationDefaults() {
        register(defaults: [NavigationSettings.showsTraffic: false,
                            NavigationSettings.showsSatellite: false,
                            NavigationSettings.volume: 3])
    }
}

struct NavigationDefaults {
    static var shared: UserDefaults? {
        get {
            let settings = UserDefaults(suiteName: "com.mapbox.MapboxNavigation")
            settings?.registerNavigationDefaults()
            return settings
        }
    }
}

struct NavigationSettings {
    static let showsTraffic = "ShowsTraffic"
    static let showsSatellite = "ShowsSatellite"
    static let volume = "Volume"
    
    static var styleURL: URL {
        get {
            if let showsSatellite = NavigationDefaults.shared?.bool(forKey: NavigationSettings.showsSatellite) {
                return showsSatellite
                    ? MGLStyle.satelliteStyleURL(withVersion: 9)
                    : MGLStyle.streetsStyleURL(withVersion: 10)
            }
            return MGLStyle.streetsStyleURL(withVersion: 10)
        }
    }
}
