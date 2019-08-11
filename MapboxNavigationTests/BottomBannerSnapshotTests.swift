import XCTest
import Foundation
import SnappyShrimp
import MapboxDirections
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class BottomBannerSnapshotTests: SnapshotTest {
    override func setUp() {
        super.setUp()
        recordMode = false
    }
    
    @available(iOS 11.0, *)
    
    func testBottomBannerViewController() {
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = BottomBannerViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: container)
        }
        
        applyStyling(to: subject)
        subject.prepareForInterfaceBuilder()

        verify(host, for: Device.iPhoneX.portrait)
    }
    
    @available(iOS 11.0, *)
    func testBottomBannerViewControllerNoSafeArea() {
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = BottomBannerViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: container)
        }
        
        applyStyling(to: subject)
        subject.prepareForInterfaceBuilder()
        
        verify(host, for: Device.iPhone8.portrait)
    }
    
    func constrain(_ child: UIView, to parent: UIView) {
        let constraints = [
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func applyStyling(to subject: BottomBannerViewController) {
        subject.bottomBannerView.backgroundColor = .white
        subject.bottomPaddingView.backgroundColor = .orange
    }
    
    func embed(parent:UIViewController, child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: parent)
        parent.addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(parent, child) {
            parent.view.addConstraints(childConstraints)
        }
        child.didMove(toParent: parent)
    }
}
