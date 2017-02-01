import UIKit
import Mapbox
import MapboxNavigation
import MapboxDirections

class RouteMapViewController: UIViewController {

    var mapView: MGLMapView!
    var pageViewController: RoutePageViewController!
    weak var routeController: RouteController!
    
    init(_ routeController: RouteController) {
        self.routeController = routeController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupPageViewController()
    }
    
    func setupMapView() {
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(mapView)
    }
    
    func setupPageViewController() {
        // Add the RoutePageViewController as a child to this view controller.
        pageViewController = RoutePageViewController()
        pageViewController.maneuverDelegate = self
        pageViewController.willMove(toParentViewController: self)
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)
        
        // Setup constraints
        let views = ["pageView": pageViewController.view]
        let pageView = pageViewController.view
        pageView?.translatesAutoresizingMaskIntoConstraints = false
        
        let top = NSLayoutConstraint(item: pageView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 10)
        let left = NSLayoutConstraint(item: pageView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 10)
        let right = NSLayoutConstraint(item: pageView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: -10)
        let height = NSLayoutConstraint(item: pageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 104)
        
        view.addConstraints([top, left, height, right])
    }
}

extension RouteMapViewController: RoutePageViewControllerDelegate {
    func routePageViewController(_ controller: RoutePageViewController, willTransitionTo routeManeuverViewController: RouteManeuverViewController) {
        // TODO: layout view
    }

    func stepBefore(_ step: RouteStep) -> RouteStep? {
        return routeController.routeProgress.currentLegProgress.stepBefore(step)
    }

    func stepAfter(_ step: RouteStep) -> RouteStep? {
        return routeController.routeProgress.currentLegProgress.stepAfter(step)
    }
    
    func currentStep() -> RouteStep {
        return routeController.routeProgress.currentLegProgress.currentStep
    }
    
    
}
