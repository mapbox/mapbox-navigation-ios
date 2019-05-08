@objc public protocol NavigationInteractionDelegate: class {
    @objc optional func navigationViewController(_ controller: NavigationViewController, didRecenterAt location: CLLocation)
}
