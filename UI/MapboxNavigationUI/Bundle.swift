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
