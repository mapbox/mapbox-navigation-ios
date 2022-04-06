import UIKit
import CoreLocation
import MapboxDirections

// :nodoc:
public protocol PreviewViewControllerDelegate: AnyObject {
    
    func previewViewControllerDidBeginNavigation(_ previewViewController: PreviewViewController)
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateDidChangeTo state: PreviewViewController.State)

    func previewViewController(_ previewViewController: PreviewViewController,
                               didLongPressFor coordinates: [CLLocationCoordinate2D])
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelectRouteAt index: Int,
                               from routeResponse: RouteResponse)
}
