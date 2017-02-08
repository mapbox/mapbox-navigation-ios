import UIKit
import MapboxNavigation
import MapboxNavigationUI
import MapboxDirections
import Mapbox
import Pulley


public class RouteViewController: PulleyViewController {
    public var route: Route!
    public var destination: MGLAnnotation!
    public var directions: Directions!
    
    public var didTapCancelHandler:()->Void={}
    
    var routeController: RouteController!
    var tableViewController: RouteTableViewController?
    
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        routeController.resume()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        routeController.suspend()
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
                controller.directions = directions
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
        didTapCancelHandler()
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
