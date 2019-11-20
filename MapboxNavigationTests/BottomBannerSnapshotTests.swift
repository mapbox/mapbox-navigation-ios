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
        constrain(container, to: host.view, side: .bottom)
        
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
        constrain(container, to: host.view, side: .bottom)
        
        embed(parent: host, child: subject, in: container) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: container)
        }
        
        applyStyling(to: subject)
        subject.prepareForInterfaceBuilder()
        
        verify(host, for: Device.iPhone8.portrait)
    }
    
    func applyStyling(to subject: BottomBannerViewController) {
        subject.bottomBannerView.backgroundColor = .white
        subject.bottomPaddingView.backgroundColor = .orange
    }
}
