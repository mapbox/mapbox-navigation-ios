import UIKit

extension UIDevice {
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    var screenOrientation: UIDeviceOrientation {
        let screenOrientation: UIDeviceOrientation
        if orientation.isValidInterfaceOrientation {
            screenOrientation = orientation
        } else if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            screenOrientation = .portrait
        } else {
            screenOrientation = .landscapeLeft
        }
        return screenOrientation
    }
}
