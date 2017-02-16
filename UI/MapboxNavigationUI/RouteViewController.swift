import UIKit
import MapboxNavigation
import MapboxDirections
import Mapbox
import Pulley

@objc(MBNavigationPulleyViewController)
public class NavigationPulleyViewController: PulleyViewController {}

/**
 `RouteViewController` is fully featured, turn by turn navigation UI.
 
 It provides step by step instructions, an overview of all steps
 for the given route and support for basic styling.
 */
@objc(MBRouteViewController)
public class RouteViewController: NavigationPulleyViewController {
    
    // A `route` object constructed by [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift)
    public var route: Route!
    
    /** 
     `destination` is an instance of `MGLAnnotation` that will be showned on
     on the destination of your route. The last coordinate of the route will be
     used if no destination is given.
    */
    public var destination: MGLAnnotation!
    
    /**
     `directions` is an instance of `Directions` need for rerouting.
     See [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift)
     for further information.
     */
    public var directions: Directions!
    
    /**
     `pendingCamera` is an optional `MGLMapCamera` you can use to improve
     the initial transition from a previous viewport and prevent a trigger
     from an excessive significant location update.
     */
    public var pendingCamera: MGLMapCamera?
    
    /**
     `origin` is an instance of `MGLAnnotation` representing the origin of your route.
     */
    public var origin: MGLAnnotation?
    
    var routeController: RouteController!
    var tableViewController: RouteTableViewController?
    var mapViewController: RouteMapViewController?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented. " +
                   "Use NavigationUI.instantiate(route:directions:) if you are instantiating programmatically " +
                   "or a storyboard reference to Navigation if you are using storyboards.")
    }
    
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
        setupRouteController()
        switch segue.identifier ?? "" {
        case "MapViewControllerSegueIdentifier":
            if let controller = segue.destination as? RouteMapViewController {
                controller.routeController = routeController
                controller.destination = destination
                controller.directions = directions
                controller.pendingCamera = pendingCamera
                mapViewController = controller
            }
        case "TableViewControllerSegueIdentifier":
            if let controller = segue.destination as? RouteTableViewController {
                controller.headerView.delegate = self
                controller.routeController = routeController
                tableViewController = controller
            }
        default:
            break
        }
    }
    
    func setupRouteController() {
        if routeController == nil {
            routeController = RouteController(route: route)
            
            if Bundle.main.backgroundModeLocationSupported {
                routeController.locationManager.activityType = .automotiveNavigation
                routeController.locationManager.allowsBackgroundLocationUpdates = true
            }
        }
        
        if destination == nil {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = route.coordinates!.last!
            destination = annotation
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.drawerCornerRadius = 0
        self.delegate = self
    }
}

extension RouteViewController: RouteTableViewHeaderViewDelegate {
    func didTapCancel() {
        dismiss(animated: true, completion: nil)
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
