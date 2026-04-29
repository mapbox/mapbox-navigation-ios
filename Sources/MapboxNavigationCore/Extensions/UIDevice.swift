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
        let screenOrientation: UIDeviceOrientation = if orientation.isValidInterfaceOrientation {
            orientation
        } else if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            .portrait
        } else {
            .landscapeLeft
        }
        return screenOrientation
    }
}
