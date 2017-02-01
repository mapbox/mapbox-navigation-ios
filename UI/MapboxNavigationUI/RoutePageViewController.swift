import UIKit
import MapboxDirections
import MapboxNavigation

protocol RoutePageViewControllerDelegate {
    func currentStep() -> RouteStep
    func stepBefore(_ step: RouteStep) -> RouteStep?
    func stepAfter(_ step: RouteStep) -> RouteStep?
    func routePageViewController(_ controller: RoutePageViewController, willTransitionTo routeManeuverViewController: RouteManeuverViewController)
}

class RoutePageViewController: UIPageViewController {
    
    var maneuverDelegate: RoutePageViewControllerDelegate!
    var currentManeuverPage: RouteManeuverViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupRoutePageViewController()
    }
    
    func setupRoutePageViewController() {
        let currentStep = maneuverDelegate.currentStep()
        let controller = routeManeuverViewController(with: currentStep)!
        setViewControllers([controller], direction: .forward, animated: false, completion: nil)
        currentManeuverPage = controller
        maneuverDelegate.routePageViewController(self, willTransitionTo: controller)
    }
    
    func routeManeuverViewController(with step: RouteStep?) -> RouteManeuverViewController? {
        guard step != nil else {
            return nil
        }
        
        let controller = RouteManeuverViewController()
        controller.step = step
        return controller
    }
}

extension RoutePageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let controller = viewController as! RouteManeuverViewController
        let stepAfter = maneuverDelegate.stepAfter(controller.step)
        return routeManeuverViewController(with: stepAfter)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let controller = viewController as! RouteManeuverViewController
        let stepBefore = maneuverDelegate.stepBefore(controller.step)
        return routeManeuverViewController(with: stepBefore)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let controller = pendingViewControllers.first! as! RouteManeuverViewController
        maneuverDelegate.routePageViewController(self, willTransitionTo: controller)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let controller = previousViewControllers.first as? RouteManeuverViewController {
                currentManeuverPage = controller
            }
        }
    }
}
