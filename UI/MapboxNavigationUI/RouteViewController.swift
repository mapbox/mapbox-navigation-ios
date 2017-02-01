import UIKit
import MapboxNavigation
import MapboxNavigationUI
import MapboxDirections
import Pulley


public class RouteViewController: PulleyViewController {
    
    var route: Route!
    var routeController: RouteController!
    
    required public init(route: Route) {
        self.route = route
        if routeController == nil {
            routeController = RouteController(route: route)
        }
        
        let mapViewController = RouteMapViewController(routeController)
        let tableViewController = RouteViewController.navigationStoryboard().instantiateViewController(withIdentifier: "RouteTableViewIdentifier") as! RouteTableViewController
        
        super.init(contentViewController: mapViewController, drawerViewController: tableViewController)
    }
    
    class func navigationStoryboard() -> UIStoryboard {
        let bundle = Bundle(for: RouteViewController.self)
        let resourceBundlePath = "\(bundle.bundlePath)/MapboxNavigationUI.bundle"
        let resourceBundle = Bundle(path: resourceBundlePath)
        return UIStoryboard(name: "Navigation", bundle: resourceBundle)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        let tableViewController = RouteViewController.navigationStoryboard().instantiateViewController(withIdentifier: "RouteTableViewIdentifier") as! RouteTableViewController
        super.init(contentViewController: self, drawerViewController: tableViewController)
    }
    
    required public init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        assertionFailure("Not implemented")
        super.init(contentViewController: contentViewController, drawerViewController: drawerViewController)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .red
    }
    
}
