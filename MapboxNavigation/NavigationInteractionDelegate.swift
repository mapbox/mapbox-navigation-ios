@objc public protocol NavigationInteractionDelegate: class {
    @objc optional func navigationViewController(_ controller: NavigationViewController, didRecenterAt location: CLLocation)
    @objc optional func navigationViewControllerDidConnectCarPlay(_ controller: NavigationViewController)
    @objc optional func navigationViewControllerDidDisconnectCarPlay(_ controller: NavigationViewController)

}
