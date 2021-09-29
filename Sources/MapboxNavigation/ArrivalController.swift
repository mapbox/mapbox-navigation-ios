import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMobileEvents
import MapboxMaps

/// A component to encapsulate `EndOfRouteViewController` presenting logic such as enabling/disabling, handling autolayout, keyboard, positioning camera, etc.
class ArrivalController: NavigationComponentDelegate {
    
    typealias EndOfRouteDismissalHandler = (EndOfRouteFeedback?) -> ()
    
    // MARK: Properties
    
    weak private(set) var navigationViewData: NavigationViewData!
    
    private var navigationMapView: NavigationMapView {
        return navigationViewData.navigationView.navigationMapView
    }
    private var topBannerContainerView: BannerContainerView {
        return navigationViewData.navigationView.topBannerContainerView
    }
    var destination: Waypoint?
    var showsEndOfRoute: Bool = true
    
    var endOfRouteIsActive: Bool {
        let show = navigationViewData.navigationView.endOfRouteShowConstraint
        return navigationViewData.navigationView.endOfRouteView != nil && show?.isActive ?? false
    }
    
    private lazy var endOfRouteViewController: EndOfRouteViewController = {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        let viewController = storyboard.instantiateViewController(withIdentifier: "EndOfRouteViewController") as! EndOfRouteViewController
        return viewController
    }()
    
    // MARK: Public Methods
    
    init(_ navigationViewData: NavigationViewData) {
        self.navigationViewData = navigationViewData
    }
    
    func showEndOfRouteIfNeeded(_ viewController: UIViewController,
                                advancesToNextLeg: Bool,
                                duration: TimeInterval = 1.0,
                                completion: ((Bool) -> Void)? = nil,
                                onDismiss: EndOfRouteDismissalHandler? = nil) {
        guard navigationViewData.router.routeProgress.isFinalLeg &&
                advancesToNextLeg &&
                showsEndOfRoute else {
            return
        }
        
        embedEndOfRoute(into: viewController, onDismiss: onDismiss)
        endOfRouteViewController.destination = destination
        navigationViewData.navigationView.endOfRouteView?.isHidden = false
        
        navigationViewData.navigationView.endOfRouteHideConstraint?.isActive = false
        navigationViewData.navigationView.endOfRouteShowConstraint?.isActive = true

        navigationMapView.navigationCamera.stop()
        
        if let height = navigationViewData.navigationView.endOfRouteHeightConstraint?.constant {
            self.navigationViewData.navigationView.floatingStackView.alpha = 0.0
            var cameraOptions = CameraOptions(cameraState: navigationMapView.mapView.cameraState)
            // Since `padding` is not an animatable property `zoom` is increased to cover up abrupt camera change.
            if let zoom = cameraOptions.zoom {
                cameraOptions.zoom = zoom + 1.0
            }
            cameraOptions.padding = UIEdgeInsets(top: topBannerContainerView.bounds.height,
                                                 left: 20,
                                                 bottom: height + 20,
                                                 right: 20)
            cameraOptions.center = destination?.coordinate
            cameraOptions.pitch = 0
            navigationMapView.mapView.camera.ease(to: cameraOptions, duration: duration) { (animatingPosition) in
                if animatingPosition == .end {
                    completion?(true)
                }
            }
        }
    }
    
    func updatePreferredContentSize(_ size: CGSize) {
        navigationViewData.navigationView.endOfRouteHeightConstraint?.constant = size.height

        UIView.animate(withDuration: 0.3, animations: navigationViewData.containerViewController.view.layoutIfNeeded)
    }
    
    // MARK: Private Methods
    
    private func embedEndOfRoute(into viewController: UIViewController, onDismiss: EndOfRouteDismissalHandler? = nil) {
        let endOfRoute = endOfRouteViewController
        viewController.addChild(endOfRoute)
        navigationViewData.navigationView.endOfRouteView = endOfRoute.view
        navigationViewData.navigationView.constrainEndOfRoute()
        endOfRoute.didMove(toParent: viewController)

        endOfRoute.dismissHandler = { [weak self] (stars, comment) in
            guard let rating = self?.rating(for: stars) else { return }
            onDismiss?(EndOfRouteFeedback(rating: rating, comment: comment))
        }
    }
    
    fileprivate func rating(for stars: Int) -> Int {
        assert(stars >= 0 && stars <= 5)
        guard stars > 0 else { return MMEEventsManager.unrated } //zero stars means this was unrated.
        return (stars - 1) * 25
    }
    
    // MARK: Keyboard Handling
    
    fileprivate func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ArrivalController.keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ArrivalController.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc fileprivate func keyboardWillShow(notification: NSNotification) {
        guard navigationViewData.navigationView.endOfRouteView != nil else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        guard let keyBoardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        navigationViewData.navigationView.endOfRouteShowConstraint?.constant = -1 * (keyBoardRect.size.height - navigationViewData.navigationView.safeAreaInsets.bottom) //subtract the safe area, which is part of the keyboard's frame
        
        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeIn
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseIn
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: navigationViewData.navigationView.layoutIfNeeded, completion: nil)
    }
    
    @objc fileprivate func keyboardWillHide(notification: NSNotification) {
        guard navigationViewData.navigationView.endOfRouteView != nil else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        navigationViewData.navigationView.endOfRouteShowConstraint?.constant = 0
        
        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeOut
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseOut
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: navigationViewData.navigationView.layoutIfNeeded, completion: nil)
    }
    
    // MARK: NavigationComponentDelegate Implementation
    
    func navigationViewWillAppear(_: Bool) {
        subscribeToKeyboardNotifications()
    }
    
    func navigationViewDidDisappear(_: Bool) {
        unsubscribeFromKeyboardNotifications()
    }
}

internal extension UIView.AnimationOptions {
    init?(curve: UIView.AnimationCurve) {
        switch curve {
        case .easeIn:
            self = .curveEaseIn
        case .easeOut:
            self = .curveEaseOut
        case .easeInOut:
            self = .curveEaseInOut
        case .linear:
            self = .curveLinear
        default:
            // Some private UIViewAnimationCurve values unknown to the compiler can leak through notifications.
            return nil
        }
    }
}
