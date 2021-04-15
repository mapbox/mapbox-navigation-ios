
import UIKit
import MapboxCoreNavigation

protocol NavigationViewData: class {
    var navigationView: NavigationView! { get }
    var navigationService: NavigationService! { get }
    var navigationViewController: UIViewController! { get }
}


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
