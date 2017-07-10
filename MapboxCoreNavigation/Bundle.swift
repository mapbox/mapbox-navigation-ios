import Foundation

extension Bundle {
    
    struct BackgroundModes {
        var location: Bool {
            return backgroundModesContains("location")
        }
        
        fileprivate func backgroundModesContains(_ key: String) -> Bool {
            if let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
                return modes.contains(key)
            }
            return false
        }
    }
    
    var backgroundModes: BackgroundModes { return BackgroundModes() }
    
    var locationAlwaysAndWhenInUseUsageDescription: String? {
        get {
            return object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") as? String
        }
    }
    
    var locationWhenInUseUsageDescription: String? {
        get {
            return object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String
        }
    }
    
    var locationAlwaysUsageDescription: String? {
        get {
            return object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") as? String
        }
    }
}
