import Foundation

extension Bundle {
    
    class var mapboxNavigation: Bundle {
        get { return Bundle(for: NavigationViewController.self) }
    }
    
    func image(named: String) -> UIImage? {
        return UIImage(named: named, in: self, compatibleWith: nil)
    }
}
