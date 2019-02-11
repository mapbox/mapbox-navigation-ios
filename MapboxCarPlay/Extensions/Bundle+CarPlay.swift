import Foundation

extension Bundle {
    @available(iOS 12.0, *)
    class var carPlay: Bundle {
        get { return Bundle(for: CarPlayNavigationViewController.self) }
    }
}
