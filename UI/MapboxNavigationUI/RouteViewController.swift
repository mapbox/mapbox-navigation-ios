import UIKit
import MapboxNavigation
import MapboxNavigationUI
import MapboxDirections
import Pulley


public class RouteViewController: PulleyViewController {
    
    public var route: Route!
    var routeController: RouteController!
    var tableViewController: RouteTableViewController?
    
    public class func create(route: Route) -> RouteViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
        let controller = storyboard.instantiateInitialViewController() as! RouteViewController
        controller.route = route
        return controller
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if routeController == nil {
            routeController = RouteController(route: route)
        }
        switch segue.identifier ?? "" {
        case "RouteMapViewController":
            if let controller = segue.destination as? RouteMapViewController {
                controller.routeController = routeController
            }
        case "RouteTableViewController":
            if let controller = segue.destination as? RouteTableViewController {
                tableViewController = controller
                controller.routeController = routeController
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
