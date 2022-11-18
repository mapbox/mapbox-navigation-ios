import UIKit
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

/**
 `PreviewViewControllerDelegate` allows to observe `Banner` presentation and dismissal events.
 */
public protocol PreviewViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    /**
     Tells the delegate that the `Banner` is about to be presented on the screen.
     
     - parameter previewViewController: `PreviewViewController` instance that performs banner
     presentation.
     - parameter banner: `Banner` that will be presented.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner)
    
    /**
     Tells the delegate that the `Banner` was presented on the screen.
     
     - parameter previewViewController: `PreviewViewController` instance that performs banner
     presentation.
     - parameter banner: `Banner` that was presented.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner)
    
    /**
     Tells the delegate that the `Banner` will disappear from the screen.
     
     - parameter previewViewController: `PreviewViewController` instance that performs banner
     dismissal.
     - parameter banner: `Banner` that will be dismissed.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner)
    
    /**
     Tells the delegate that the `Banner` disappeared from the screen.
     
     - parameter previewViewController: `PreviewViewController` instance that performs banner
     dismissal.
     - parameter banner: `Banner` that was dismissed.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner)
}

public extension PreviewViewControllerDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
}
