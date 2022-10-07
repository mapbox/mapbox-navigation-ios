import UIKit
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

// :nodoc:
public protocol PreviewViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    func willPreviewRoutes(_ previewViewController: PreviewViewController)
    
    func willBeginActiveNavigation(_ previewViewController: PreviewViewController)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D])
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent destinationText: NSAttributedString,
                               in destinationPreviewViewController: DestinationPreviewViewController) -> NSAttributedString?
    
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
    
    func willPreviewRoutes(_ previewViewController: PreviewViewController) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func willBeginActiveNavigation(_ previewViewController: PreviewViewController) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D]) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent destinationText: NSAttributedString,
                               in destinationPreviewViewController: DestinationPreviewViewController) -> NSAttributedString? {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
        return nil
    }
    
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
