import UIKit
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

// :nodoc:
public protocol PreviewViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    func previewViewControllerWillPreviewRoutes(_ previewViewController: PreviewViewController)
    
    func previewViewControllerWillBeginNavigation(_ previewViewController: PreviewViewController)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateWillChangeTo state: Preview.State)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateDidChangeTo state: Preview.State)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D])
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               bottomBannerFor state: Preview.State) -> BannerPreviewing?
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent destinationText: NSAttributedString,
                               in destinationPreviewViewController: DestinationPreviewViewController) -> NSAttributedString?
}

// :nodoc:
public extension PreviewViewControllerDelegate {
    
    func previewViewControllerWillPreviewRoutes(_ previewViewController: PreviewViewController) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewControllerWillBeginNavigation(_ previewViewController: PreviewViewController) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateWillChangeTo state: Preview.State) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateDidChangeTo state: Preview.State) {
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
                               bottomBannerFor state: Preview.State) -> BannerPreviewing? {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent destinationText: NSAttributedString,
                               in destinationPreviewViewController: DestinationPreviewViewController) -> NSAttributedString? {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
        return nil
    }
}
