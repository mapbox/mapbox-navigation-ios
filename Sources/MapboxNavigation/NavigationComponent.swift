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
     Shows the status view for a specified amount of time.
     */
    
    // TODO: DELETE THIS METHOD
    func showStatus(title: String, spinner: Bool, duration: TimeInterval, animated: Bool, interactive: Bool)
    
    func addNewStatus(status: StatusView.Status)
    
    func hideStatus(usingStatusId: String?, usingStatus: StatusView.Status?, delay: TimeInterval)
}
