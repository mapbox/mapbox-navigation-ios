import UIKit

extension Bundle {
    /**
     The Mapbox Navigation framework bundle.
     */
    public class var mapboxNavigation: Bundle {
        get {
            #if SWIFT_PACKAGE
            return .module
            #else
            return Bundle(for: NavigationViewController.self)
            #endif
        }
    }
    
    func image(named: String) -> UIImage? {
        return UIImage(named: named, in: self, compatibleWith: nil)
    }
    
    var microphoneUsageDescription: String? {
        get {
            let para = "NSMicrophoneUsageDescription"
            let key = "Privacy - Microphone Usage Description"
            return object(forInfoDictionaryKey: para) as? String ?? object(forInfoDictionaryKey: key) as? String
        }
    }
}
