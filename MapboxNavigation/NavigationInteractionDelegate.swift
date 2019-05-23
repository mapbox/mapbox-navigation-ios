
/**
 The NavigationInteractionDelegate protocol is used to define interaction events that the top banner may need to know about.
 */
@objc public protocol NavigationInteractionDelegate: class {
    
    /**
     Called when the NavigationMapView centers on a location.
     */
    @objc(navigationViewController:didCenterOnLocation:)
    optional func navigationViewController(_ controller: NavigationViewController, didCenterOn location: CLLocation)
    
    /**
     Called when the NavigationViewController detects that a CarPlay device has been connected.
     */
    @objc(navigationViewControllerDidConnectCarPlay:)
    optional func navigationViewControllerDidConnectCarPlay(_ controller: NavigationViewController)
    
    /**
     Called when the NavigationViewController detects that a CarPlay device has been connected.
     */
    @objc(navigationViewControllerDidDisconnectCarPlay:)
    optional func navigationViewControllerDidDisconnectCarPlay(_ controller: NavigationViewController)
}


/**
 This protocol defines a UI Component that is capable of presenting a status message.
 */
@objc public protocol NavigationStatusPresenter: class {
    /**
     Shows the status view for a specified amount of time.
     */
    @objc optional func showStatus(title: String, spinner: Bool, duration: TimeInterval, animated: Bool, interactive: Bool)
}
