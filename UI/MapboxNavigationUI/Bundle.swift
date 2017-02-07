import Foundation

extension Bundle {
    class var navigationUI: Bundle {
        get {
            let bundle = Bundle(for: RouteViewController.self)
            let resourceBundlePath = "\(bundle.bundlePath)/MapboxNavigationUI.bundle"
            return Bundle(path: resourceBundlePath)!
        }
    }
}

var ShieldImageNamesByPrefix: [String: String] = {
    guard let plistPath = Bundle.navigationUI.path(forResource: "Shields", ofType: "plist") else {
        return [:]
    }
    return NSDictionary(contentsOfFile: plistPath) as! [String: String]
}()
