import Foundation
import MapboxCoreNavigation
import CoreLocation

/*
 A navigation component is a member of the navigation UI view hierarchy that responds as the user progresses along a route according to the `NavigationServiceDelegate` protocol.
 */
@objc public protocol NavigationComponent: NavigationServiceDelegate {}


/**
 The NavigationInteractionDelegate protocol is used to define interaction events that the top banner may need to know about.
 */
@objc public protocol NavigationMapInteractionObserver: class {
    /**
     Called when the NavigationMapView centers on a location.
     */
    @objc(navigationViewControllerDidCenterOnLocation:)
    func navigationViewController(didCenterOn location: CLLocation)
}

/**
 The CarPlayConnectionObserver protocol provides notification of a carplay unit connecting two the NavigationViewController.
 */
@objc public protocol CarPlayConnectionObserver: class {
    
    /**
     Called when the NavigationViewController detects that a CarPlay device has been connected.
     */
    @objc func didConnectToCarPlay()
    
    /**
     Called when the NavigationViewController detects that a CarPlay device has been connected.
     */
    @objc func didDisconnectFromCarPlay()
}


/**
 This protocol defines a UI Component that is capable of presenting a status message.
 */
@objc public protocol NavigationStatusPresenter: class {
    /**
     Shows the status view for a specified amount of time.
     */
    @objc func showStatus(title: String, spinner: Bool, duration: TimeInterval, animated: Bool, interactive: Bool)
}
