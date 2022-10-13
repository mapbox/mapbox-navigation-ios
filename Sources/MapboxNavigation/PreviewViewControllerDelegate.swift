import UIKit
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

// :nodoc:
public protocol PreviewViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    func didPressPreviewRoutesButton(_ previewViewController: PreviewViewController)
    
    func didPressBeginActiveNavigationButton(_ previewViewController: PreviewViewController)
    
    func didPressDismissBannerButton(_ previewViewController: PreviewViewController)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D])
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route)
    
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
    
    func didPressPreviewRoutesButton(_ previewViewController: PreviewViewController) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func didPressBeginActiveNavigationButton(_ previewViewController: PreviewViewController) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func didPressDismissBannerButton(_ previewViewController: PreviewViewController) {
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
