import UIKit
import MapboxNavigation
import MapboxDirections
import Mapbox
import Pulley

/**
 `RouteViewController` is fully featured, turn by turn navigation UI.
 
 It provides step by step instructions, an overview of all steps
 for the given route and support for basic styling.
 */
public class RouteViewController: PulleyViewController {
    
    /// A `route` object constructed by [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift)
    public var route: Route!
    
    // TODO:
    public var destination: MGLAnnotation!
    
    // TODO:
    public var directions: Directions!
    
    /**
     `pendingCamera` is an optional `MGLMapCamera` you can use to improve
     the initial transition from a previous viewport and prevent a trigger
     from an excessive significant location update.
     */
    public var pendingCamera: MGLMapCamera?
    
    // TODO:
    public var origin: MGLAnnotation?
    
    var routeController: RouteController!
    var tableViewController: RouteTableViewController?
    var mapViewController: RouteMapViewController?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented")
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
