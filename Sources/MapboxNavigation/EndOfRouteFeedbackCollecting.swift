import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMobileEvents


public protocol EndOfRouteFeedbackCollecting: UIViewController {
    typealias EndOfRouteDismissalHandler = (EndOfRouteFeedback?) -> ()
    
//    private var endOfRouteViewController: EndOfRouteViewController // expose via protocol?
    
    func showEndOfRouteFeedbackCollection(destination: Waypoint?,
                                          onDismiss: EndOfRouteDismissalHandler?) -> UIViewController
}

extension EndOfRouteFeedbackCollecting {
    typealias EndOfRouteViewConstraints = (show: NSLayoutConstraint, hide: NSLayoutConstraint)
    
    private var endOfRouteViewController: EndOfRouteViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        let viewController = storyboard.instantiateViewController(withIdentifier: "EndOfRouteViewController") as! EndOfRouteViewController
        return viewController
    }
    
    public func showEndOfRouteFeedbackCollection(destination: Waypoint?,
                                          onDismiss: EndOfRouteDismissalHandler? = nil) -> UIViewController {
        let endOfRoute = endOfRouteViewController
        let endOfRouteViewConstraints = (
            show: endOfRoute.view.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            hide: endOfRoute.view.topAnchor.constraint(equalTo: view.bottomAnchor)
        )
        
        embed(endOfRoute: endOfRoute,
              endOfRouteViewConstraints: endOfRouteViewConstraints,
              onDismiss: onDismiss)
        endOfRouteViewController.destination = destination
        view.isHidden = false
        
        endOfRouteViewConstraints.hide.isActive = false
        endOfRouteViewConstraints.show.isActive = true
        
        return endOfRoute
    }
    
    // MARK: - Private methods
    
    private func embed(endOfRoute: EndOfRouteViewController, endOfRouteViewConstraints: EndOfRouteViewConstraints, onDismiss: EndOfRouteDismissalHandler? = nil) {
        addChild(endOfRoute)
        view.addSubview(endOfRoute.view)
        endOfRoute.view.translatesAutoresizingMaskIntoConstraints = false

        endOfRouteViewConstraints.hide.isActive = true
        endOfRoute.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        endOfRoute.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        endOfRoute.view.layoutIfNeeded()
        
        endOfRoute.didMove(toParent: self)
        let observerTokens = subscribeToKeyboardNotifications(endOfRouteViewConstraints)
        
        endOfRoute.dismissHandler = { [weak self] (stars, comment) in
            self?.unsubscribeFromKeyboardNotifications(observerTokens)
            
            if let active: [NSLayoutConstraint] = self?.view.constraints(affecting: endOfRoute.view) {
                NSLayoutConstraint.deactivate(active)
            }
            endOfRoute.view.removeFromSuperview()
            
            guard let rating = self?.rating(for: stars) else { return }
            onDismiss?(EndOfRouteFeedback(rating: rating, comment: comment))
        }
    }
    
    fileprivate func rating(for stars: Int) -> Int {
        assert(stars >= 0 && stars <= 5)
        guard stars > 0 else { return MMEEventsManager.unrated } //zero stars means this was unrated.
        return (stars - 1) * 25
    }
    
    // MARK: - Keyboard handling
    
    fileprivate func subscribeToKeyboardNotifications(_ endOfRouteViewConstraints: EndOfRouteViewConstraints) -> [NSObjectProtocol] {
        return [
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
                self?.keyboardWillShow(notification: notification, endOfRouteViewConstraints: endOfRouteViewConstraints)
            },
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
                self?.keyboardWillHide(notification: notification, endOfRouteViewConstraints: endOfRouteViewConstraints)
            }
        ]
    }
    
    fileprivate func unsubscribeFromKeyboardNotifications(_ tokens: [NSObjectProtocol]) {
        tokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }
    
    fileprivate func keyboardWillShow(notification: Notification, endOfRouteViewConstraints: EndOfRouteViewConstraints) {
        guard isViewLoaded else { return } // endOfRouteView
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        guard let keyBoardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        endOfRouteViewConstraints.show.constant = -1 * (keyBoardRect.size.height - view.safeAreaInsets.bottom) //subtract the safe area, which is part of the keyboard's frame
        
        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeIn
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseIn
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: view.layoutIfNeeded, completion: nil)
    }
    
    fileprivate func keyboardWillHide(notification: Notification, endOfRouteViewConstraints: EndOfRouteViewConstraints) {
        guard isViewLoaded else { return } // endOfRouteView
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        endOfRouteViewConstraints.show.constant = 0
        
        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeOut
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseOut
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: view.layoutIfNeeded, completion: nil)
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
