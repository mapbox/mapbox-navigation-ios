import UIKit
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

// :nodoc:
public protocol PreviewViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner)
}

// :nodoc:
public extension PreviewViewControllerDelegate {
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
}
