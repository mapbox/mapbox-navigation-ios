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
public protocol NavigationMapInteractionObserver: AnyObject {
    /**
     Called when the NavigationMapView centers on a location.
     */
    func navigationViewController(didCenterOn location: CLLocation)
}

/**
 The CarPlayConnectionObserver protocol provides notification of a carplay unit connecting two the NavigationViewController.
 */
public protocol CarPlayConnectionObserver: AnyObject {
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
public protocol NavigationStatusPresenter: AnyObject {
    /**
     Shows a Status for a specified amount of time.
     */
    func show(_: StatusView.Status)
    
    /**
     Hides a given Status without hiding the status view.
     */
    func hide(_: StatusView.Status)
}
