
@objc public protocol NavigationInteractionDelegate: class {
    
    @objc optional func navigationViewController(_ controller: NavigationViewController, didRecenterAt location: CLLocation)
    @objc optional func navigationViewControllerDidConnectCarPlay(_ controller: NavigationViewController)
    @objc optional func navigationViewControllerDidDisconnectCarPlay(_ controller: NavigationViewController)
    @objc optional func showStatus(title: String, withSpinner: Bool, for time: TimeInterval, animated: Bool, interactive: Bool)

}
