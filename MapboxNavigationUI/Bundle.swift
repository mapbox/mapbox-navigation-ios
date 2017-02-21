import Foundation

extension Bundle {
    class var navigationUI: Bundle {
        get {
            let bundle = Bundle(for: RouteViewController.self)
            let resourceBundlePath = "\(bundle.bundlePath)/MapboxNavigationUI.bundle"
            return Bundle(path: resourceBundlePath)!
        }
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
