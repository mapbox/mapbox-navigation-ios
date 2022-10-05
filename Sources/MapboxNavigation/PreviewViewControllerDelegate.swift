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
    
    func bannerWillAppear(_ previewViewController: PreviewViewController,
                          banner: BannerPreviewing)
    
    func bannerDidAppear(_ previewViewController: PreviewViewController,
                         banner: BannerPreviewing)
    
    func bannerWillDisappear(_ previewViewController: PreviewViewController,
                             banner: BannerPreviewing)
    
    func bannerDidDisappear(_ previewViewController: PreviewViewController,
                            banner: BannerPreviewing)
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
    
    func bannerWillAppear(_ previewViewController: PreviewViewController,
                          banner: BannerPreviewing) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func bannerDidAppear(_ previewViewController: PreviewViewController,
                         banner: BannerPreviewing) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func bannerWillDisappear(_ previewViewController: PreviewViewController,
                             banner: BannerPreviewing) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
    
    func bannerDidDisappear(_ previewViewController: PreviewViewController,
                            banner: BannerPreviewing) {
        logUnimplemented(protocolType: PreviewViewControllerDelegate.self, level: .debug)
    }
}
