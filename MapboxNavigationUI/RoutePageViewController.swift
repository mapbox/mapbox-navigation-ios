import UIKit
import MapboxDirections
import MapboxNavigation

protocol RoutePageViewControllerDelegate {
    func currentStep() -> RouteStep
    func stepBefore(_ step: RouteStep) -> RouteStep?
    func stepAfter(_ step: RouteStep) -> RouteStep?
    func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController)
}

class RoutePageViewController: UIPageViewController {
    
    var maneuverDelegate: RoutePageViewControllerDelegate!
    var currentManeuverPage: RouteManeuverViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.clipsToBounds = false
        // Disable clipsToBounds on the hidden UIQueuingScrollView to render the shadows properly
        view.subviews.first?.clipsToBounds = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupRoutePageViewController()
    }
    
    func didReRoute(_ notification: NSNotification) {
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
        
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
        let controller = storyboard.instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
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
