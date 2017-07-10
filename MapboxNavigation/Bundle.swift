import Foundation

extension Bundle {
    
    struct BackgroundModes {
        var location: Bool {
            return backgroundModesContains("location")
        }
        
        var audio: Bool {
            return backgroundModesContains("audio")
        }
        
        fileprivate func backgroundModesContains(_ key: String) -> Bool {
            if let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
                return modes.contains(key)
            }
            return false
        }
    }
    
    var backgroundModes: BackgroundModes { return BackgroundModes() }
    
    class var navigationUI: Bundle {
        get { return Bundle(for: NavigationViewController.self) }
    }
}

var ShieldImageNamesByPrefix: [String: String] = {
    guard let plistPath = Bundle.navigationUI.path(forResource: "Shields", ofType: "plist") else {
        return [:]
    }
    return NSDictionary(contentsOfFile: plistPath) as! [String: String]
}()
