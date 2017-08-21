import Foundation

extension Bundle {
    
    class var mapboxNavigation: Bundle {
        get { return Bundle(for: NavigationViewController.self) }
    }
    
    func image(named: String) -> UIImage? {
        return UIImage(named: named, in: self, compatibleWith: nil)
    }
}

var ShieldImageNamesByPrefix: [String: String] = {
    guard let plistPath = Bundle.mapboxNavigation.path(forResource: "Shields", ofType: "plist") else {
        return [:]
    }
    return NSDictionary(contentsOfFile: plistPath) as! [String: String]
}()
