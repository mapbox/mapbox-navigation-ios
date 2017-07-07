import Foundation

extension Bundle {
    
    var backgroundModeLocationSupported: Bool {
        get {
            if let modes = object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
                return modes.contains("location")
            }
            return false
        }
    }
    
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
