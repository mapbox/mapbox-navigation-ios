
@objc public protocol NavigationInteractionDelegate: class {
    @objc(navigationViewController:didCenterOnLocation:)
    optional func navigationViewController(_ controller: NavigationViewController, didCenterOn location: CLLocation)
    
    @objc(navigationViewControllerDidConnectCarPlay:)
    optional func navigationViewControllerDidConnectCarPlay(_ controller: NavigationViewController)
    
    @objc(navigationViewControllerDidDisconnectCarPlay:)
    optional func navigationViewControllerDidDisconnectCarPlay(_ controller: NavigationViewController)
}

@objc public protocol NavigationStatusPresenter: class {
    
    /**
     Shows the status view for a specified amount of time.
     */
    @objc optional func showStatus(title: String, spinner: Bool, duration: TimeInterval, animated: Bool, interactive: Bool)
}
