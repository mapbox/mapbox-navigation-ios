import UIKit

extension UIDevice {
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #endif
        
        return false
    }
}
