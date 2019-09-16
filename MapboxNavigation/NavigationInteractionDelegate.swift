
public protocol NavigationInteractionDelegate: class {
    
    optional func navigationViewController(_ controller: NavigationViewController, didRecenterAt location: CLLocation)
    optional func navigationViewControllerDidConnectCarPlay(_ controller: NavigationViewController)
    optional func navigationViewControllerDidDisconnectCarPlay(_ controller: NavigationViewController)
    optional func showStatus(title: String, withSpinner: Bool, for time: TimeInterval, animated: Bool, interactive: Bool)

}
