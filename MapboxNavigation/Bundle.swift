import Foundation

extension Bundle {
    class var navigationUI: Bundle {
        get { return Bundle(for: NavigationViewController.self) }
    }
    
    var backgroundModeLocationSupported: Bool {
        get {
            if let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
                return modes.contains("location")
            }
            return false
        }
    }
}

var ShieldImageNamesByPrefix: [String: String] = {
    guard let plistPath = Bundle.navigationUI.path(forResource: "Shields", ofType: "plist") else {
        return [:]
    }
    return NSDictionary(contentsOfFile: plistPath) as! [String: String]
}()
