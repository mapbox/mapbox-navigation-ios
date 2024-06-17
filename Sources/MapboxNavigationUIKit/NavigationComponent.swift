import CoreLocation
import MapboxDirections
import MapboxNavigationCore

/// A navigation component is a member of the navigation UI view hierarchy that responds as the user progresses along a
/// route.
public protocol NavigationComponent {
    func onWillReroute()
    func onDidReroute()

    func onFasterRoute()

    func onRouteProgressUpdated(_ progress: RouteProgress)

    func onSwitchingToOnline()

    func onDidPassVisualInstructionPoint(_ instruction: VisualInstructionBanner)

    func onDidBeginSimulating()

    func onWillEndSimulating()
}

extension NavigationComponent {
    public func onWillReroute() {}
    public func onDidReroute() {}
    public func onFasterRoute() {}
    public func onRouteProgressUpdated(_ progress: RouteProgress) {}
    public func onSwitchingToOnline() {}
    public func onDidPassVisualInstructionPoint(_ instruction: VisualInstructionBanner) {}
    public func onDidBeginSimulating() {}
    public func onWillEndSimulating() {}
}

/// The ``NavigationMapInteractionObserver`` protocol is used to define interaction events that the top banner may need
/// to
/// know about.
public protocol NavigationMapInteractionObserver: AnyObject {
    /// Called when the `NavigationMapView` centers on a location.
    /// - Parameter location: The center location.
    func navigationViewController(didCenterOn location: CLLocation)
}

/// The ``CarPlayConnectionObserver`` protocol provides notification of a carplay unit connecting two the
/// ``NavigationViewController``.
public protocol CarPlayConnectionObserver: AnyObject {
    /// Called when the ``NavigationViewController`` detects that a CarPlay device has been connected.
    func didConnectToCarPlay()

    /// Called when the ``NavigationViewController`` detects that a CarPlay device has been connected.
    func didDisconnectFromCarPlay()
}

/// This protocol defines a UI Component that is capable of presenting a status message.
public protocol NavigationStatusPresenter: AnyObject {
    /// Shows a Status for a specified amount of time.
    /// - Parameter _: The status to be displayed.
    func show(_: StatusView.Status)

    /// Hides a given Status without hiding the status view.
    /// - Parameter _:  The status to be hidden.
    func hide(_: StatusView.Status)
}
