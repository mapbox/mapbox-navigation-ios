import Foundation
import MapboxCoreNavigation
import CoreLocation

/**
 A navigation component is a member of the navigation UI view hierarchy that responds as the user progresses along a route according to the `NavigationServiceDelegate` protocol.
 */
public protocol NavigationComponent: NavigationServiceDelegate {}

/**
 The NavigationInteractionDelegate protocol is used to define interaction events that the top banner may need to know about.
 */
public protocol NavigationMapInteractionObserver: class {
    /**
     Called when the NavigationMapView centers on a location.
     */
    func navigationViewController(didCenterOn location: CLLocation)
}

/**
 The CarPlayConnectionObserver protocol provides notification of a carplay unit connecting two the NavigationViewController.
 */
public protocol CarPlayConnectionObserver: class {
    /**
     Called when the NavigationViewController detects that a CarPlay device has been connected.
     */
    func didConnectToCarPlay()
    
    /**
     Called when the NavigationViewController detects that a CarPlay device has been connected.
     */
    func didDisconnectFromCarPlay()
}

/**
 This protocol defines a UI Component that is capable of presenting a status message.
 */
public protocol NavigationStatusPresenter: class {
    /**
     Shows a Status for a specified amount of time.
     */
    func show(_: StatusView.Status)
    
    /**
     Hides a given Status without hiding the status view.
     */
    func hide(_: StatusView.Status)
    
    /**
     Shows the status view for a specified amount of time.
     `showStatus()` uses a default value for priority and the title input as identifier. To use these variables, use `show(_:)`
     */
    @available(*, deprecated, message: "Add a status using show(_:) instead")
    func showStatus(title: String, spinner spin: Bool, duration: TimeInterval, animated: Bool, interactive: Bool)
}
