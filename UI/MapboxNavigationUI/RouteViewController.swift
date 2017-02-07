import UIKit
import MapboxNavigation
import MapboxNavigationUI
import MapboxDirections
import Mapbox
import Pulley

public protocol RouteViewControllerDelegate {
    func routeViewControllerDidTapCancel()
}

public class RouteViewController: PulleyViewController {
    
    public var route: Route!
    public var destination: MGLAnnotation!
    public var routeDelegate: RouteViewControllerDelegate?
    
    var routeController: RouteController!
    var tableViewController: RouteTableViewController?
    
    public class func create(route: Route) -> RouteViewController {
        let destination = MGLPointAnnotation()
        destination.coordinate = route.coordinates!.last!
        
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
        let controller = storyboard.instantiateInitialViewController() as! RouteViewController
        controller.route = route
        controller.destination = destination
        
        return controller
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if routeController == nil {
            routeController = RouteController(route: route)
            
            if Bundle.main.backgroundModeLocationSupported {
                routeController.locationManager.activityType = .automotiveNavigation
                routeController.locationManager.allowsBackgroundLocationUpdates = true
            }
        }
        switch segue.identifier ?? "" {
        case "RouteMapViewController":
            if let controller = segue.destination as? RouteMapViewController {
                controller.routeController = routeController
                controller.delegate = self
            }
        case "RouteTableViewController":
            if let controller = segue.destination as? RouteTableViewController {
                controller.headerView.delegate = self
                controller.routeController = routeController
                tableViewController = controller
            }
        default:
            break
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.drawerCornerRadius = 0
        self.delegate = self
    }
}

extension RouteViewController: RouteMapViewControllerDelegate {
    internal func routeDestination() -> MGLAnnotation {
        return destination
    }
}

extension RouteViewController: RouteTableViewHeaderViewDelegate {
    func didTapCancel() {
        routeDelegate?.routeViewControllerDidTapCancel()
    }
}

extension RouteViewController: PulleyDelegate {
    public func drawerPositionDidChange(drawer: PulleyViewController) {
        switch drawer.drawerPosition {
        case .open:
            tableViewController?.tableView.isScrollEnabled = true
            break
        case .partiallyRevealed:
            tableViewController?.tableView.isScrollEnabled = true
            break
        case .collapsed:
            tableViewController?.tableView.isScrollEnabled = false
            break
        case .closed:
            break
        }
    }
}
