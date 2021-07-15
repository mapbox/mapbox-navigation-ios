import UIKit
import MapboxCoreNavigation

/// Protocol used by `NavigationViewController`'s components to get required data and manipulate it's contents.
protocol NavigationViewData: AnyObject {
    var navigationView: NavigationView { get }
    var router: Router { get }
    var containerViewController: UIViewController { get }
}

/// Protocol for observing basic `ViewController.view` lifecycle events.
///
/// Used by `NavigationViewController`'s components to monitor key events.
protocol NavigationComponentDelegate {
    func navigationViewDidLoad(_: UIView)
    func navigationViewWillAppear(_: Bool)
    func navigationViewDidAppear(_: Bool)
    func navigationViewWillDisappear(_: Bool)
    func navigationViewDidDisappear(_: Bool)
    func navigationViewDidLayoutSubviews()
}

extension NavigationComponentDelegate {
    func navigationViewDidLoad(_: UIView) {}
    func navigationViewWillAppear(_: Bool) {}
    func navigationViewDidAppear(_: Bool) {}
    func navigationViewWillDisappear(_: Bool) {}
    func navigationViewDidDisappear(_: Bool) {}
    func navigationViewDidLayoutSubviews() {}
}
