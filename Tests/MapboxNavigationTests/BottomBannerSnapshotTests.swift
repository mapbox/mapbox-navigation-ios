import XCTest
import Foundation
import MapboxDirections
import SnapshotTesting
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class BottomBannerSnapshotTests: TestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
        DayStyle().apply()
    }
    
    func testBottomBannerViewController() {
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = BottomBannerViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view, side: .bottom)
        
        host.embed(subject, in: container) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: container)
        }
        
        applyStyling(to: subject)
        subject.prepareForInterfaceBuilder()

        assertImageSnapshot(matching: host, as: .image(precision: 0.95))
    }
    
    func testBottomBannerViewControllerNoSafeArea() {
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = BottomBannerViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view, side: .bottom)
        
        host.embed(subject, in: container) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: container)
        }
        
        applyStyling(to: subject)
        subject.prepareForInterfaceBuilder()
        
        assertImageSnapshot(matching: host, as: .image(precision: 0.95))
    }
    
    func applyStyling(to subject: BottomBannerViewController) {
        subject.bottomBannerView.backgroundColor = .white
        subject.bottomPaddingView.backgroundColor = .orange
    }
}
