import MapboxNavigation

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        navigationViewController.dismiss(animated: false, completion: nil)
    }
}
