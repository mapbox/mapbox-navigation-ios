import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import UIKit

/// A component to encapsulate `EndOfRouteViewController` presenting logic such as enabling/disabling, handling
/// autolayout, keyboard, positioning camera, etc.
class ArrivalController: NavigationComponentDelegate {
    typealias EndOfRouteDismissalHandler = () -> Void

    // MARK: Properties

    private(set) weak var navigationViewData: NavigationViewData?

    private var navigationMapView: NavigationMapView? {
        return navigationViewData?.navigationView.navigationMapView
    }

    private var topBannerContainerView: BannerContainerView? {
        return navigationViewData?.navigationView.topBannerContainerView
    }

    var destination: Waypoint?
    var showsEndOfRoute: Bool = true
    private func endOfRoutePresented(in viewController: UIViewController) -> Bool {
        viewController.children.contains {
            $0 == endOfRouteViewController
        }
    }

    private lazy var endOfRouteViewController: EndOfRouteViewController = {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        let viewController = storyboard
            .instantiateViewController(withIdentifier: "EndOfRouteViewController") as! EndOfRouteViewController
        return viewController
    }()

    weak var eventsManager: NavigationEventsManager?

    init(_ navigationViewData: NavigationViewData, eventsManager: NavigationEventsManager?) {
        self.navigationViewData = navigationViewData
        self.eventsManager = eventsManager
    }

    func showEndOfRouteIfNeeded(
        _ viewController: UIViewController,
        advancesToNextLeg: Bool,
        duration: TimeInterval = 1.0,
        completion: ((Bool) -> Void)? = nil,
        onDismiss: @escaping EndOfRouteDismissalHandler
    ) {
        guard let navigationViewData else {
            completion?(false)
            return
        }
        Task { @MainActor in
            guard navigationViewData.mapboxNavigation.navigation().currentRouteProgress?.routeProgress
                .isFinalLeg ?? false,
                advancesToNextLeg,
                showsEndOfRoute,
                !endOfRoutePresented(in: viewController)
            else {
                completion?(false)
                return
            }
            let navigationMapView = navigationViewData.navigationView.navigationMapView
            embedEndOfRoute(into: viewController, onDismiss: onDismiss)
            endOfRouteViewController.destination = destination

            let leftInset = navigationMapView.navigationCamera.viewportDataSource.currentNavigationCameraOptions
                .followingCamera.padding?.left
            let rightInset = navigationMapView.navigationCamera.viewportDataSource.currentNavigationCameraOptions
                .followingCamera.padding?.right

            navigationMapView.navigationCamera.stop()

            if let height = navigationViewData.navigationView.endOfRouteHeightConstraint?.constant {
                navigationViewData.navigationView.floatingStackView.alpha = 0.0
                var cameraOptions = CameraOptions(cameraState: navigationMapView.mapView.mapboxMap.cameraState)
                // Since `padding` is not an animatable property `zoom` is increased to cover up abrupt camera change.
                if let zoom = cameraOptions.zoom {
                    cameraOptions.zoom = zoom + 1.0
                }

                cameraOptions.padding = UIEdgeInsets(
                    top: navigationViewData.navigationView.topBannerContainerView.bounds.height,
                    left: leftInset ?? 20,
                    bottom: height + 20,
                    right: rightInset ?? 20
                )
                cameraOptions.center = destination?.coordinate
                cameraOptions.pitch = 0
                navigationMapView.mapView.camera.ease(to: cameraOptions, duration: duration) { animatingPosition in
                    if animatingPosition == .end {
                        completion?(true)
                    }
                }
            }
        }
    }

    func updatePreferredContentSize(_ size: CGSize) {
        guard let navigationViewData else { return }
        navigationViewData.navigationView.endOfRouteHeightConstraint?.constant = size.height

        UIView.animate(withDuration: 0.3, animations: navigationViewData.containerViewController.view.layoutIfNeeded)
    }

    // MARK: Private Methods

    private func embedEndOfRoute(
        into viewController: UIViewController,
        onDismiss: @escaping EndOfRouteDismissalHandler
    ) {
        guard let navigationViewData else { return }
        let endOfRoute = endOfRouteViewController
        viewController.addChild(endOfRoute)
        navigationViewData.navigationView.endOfRouteView = endOfRoute.view
        navigationViewData.navigationView.showEndOfRoute()
        endOfRoute.didMove(toParent: viewController)

        endOfRoute.dismissHandler = { [weak self] stars, comment in
            let feedbackRating = self?.rating(for: stars)
            if let feedbackRating, let eventsManager = self?.eventsManager {
                Task { @MainActor in
                    guard let feedbackEvent = await eventsManager.createFeedback() else { return }
                    let eventType = ActiveNavigationFeedbackType.arrival(rating: feedbackRating)
                    eventsManager.sendActiveNavigationFeedback(
                        feedbackEvent,
                        type: eventType,
                        description: comment
                    )
                }
            }
            onDismiss()
        }
    }

    fileprivate func rating(for stars: Int) -> Int? {
        assert(stars >= 0 && stars <= 5)
        guard stars > 0 else { return nil }
        return (stars - 1) * 25
    }

    // MARK: Keyboard Handling

    fileprivate func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ArrivalController.keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ArrivalController.keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    fileprivate func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc
    fileprivate func keyboardWillShow(notification: NSNotification) {
        guard let navigationViewData,
              navigationViewData.navigationView.endOfRouteView != nil else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        guard let keyBoardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        navigationViewData.navigationView.endOfRouteShowConstraint?
            .constant = -1 *
            (
                keyBoardRect.size.height - navigationViewData.navigationView.safeAreaInsets
                    .bottom
            ) // subtract the safe area, which is part of the keyboard's frame

        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeIn
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseIn
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: navigationViewData.navigationView.layoutIfNeeded,
            completion: nil
        )
    }

    @objc
    fileprivate func keyboardWillHide(notification: NSNotification) {
        guard let navigationViewData,
              navigationViewData.navigationView.endOfRouteView != nil else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        navigationViewData.navigationView.endOfRouteShowConstraint?.constant = 0

        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeOut
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseOut
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: navigationViewData.navigationView.layoutIfNeeded,
            completion: nil
        )
    }

    // MARK: NavigationComponentDelegate Implementation

    func navigationViewWillAppear(_: Bool) {
        subscribeToKeyboardNotifications()
    }

    func navigationViewDidDisappear(_: Bool) {
        unsubscribeFromKeyboardNotifications()
    }
}

extension UIView.AnimationOptions {
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
