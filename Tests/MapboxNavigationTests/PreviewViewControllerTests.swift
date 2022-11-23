import XCTest
import TestHelper
@testable import MapboxNavigation

class PreviewViewControllerDelegateMock: PreviewViewControllerDelegate {
    
    var didCallWillPresentBanner = false
    var didCallDidPresentBanner = false
    var didCallBannerWillDisappear = false
    var didCallBannerDidDisappear = false
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner) {
        didCallWillPresentBanner = true
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner) {
        didCallDidPresentBanner = true
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner) {
        didCallBannerWillDisappear = true
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner) {
        didCallBannerDidDisappear = true
    }
}

final class PreviewViewControllerTests: TestCase {
    
    var previewViewControllerDelegateMock: PreviewViewControllerDelegateMock!
    
    override func setUpWithError() throws {
        previewViewControllerDelegateMock = PreviewViewControllerDelegateMock()
    }

    func testPreviewViewControllerCamera() {
        let previewViewController = PreviewViewController()
        
        XCTAssertEqual(previewViewController.navigationMapView.navigationCamera.state, .following)
    }
    
    func testPreviewViewControllerStyle() {
        let previewViewController = PreviewViewController()
        
        XCTAssertEqual(previewViewController.previewOptions.styles, nil)
        XCTAssertEqual(previewViewController.styleManager.styles.count, 2)
        XCTAssertEqual(previewViewController.styleManager.styles[safe: 0]?.styleType, .day)
        XCTAssertEqual(previewViewController.styleManager.styles[safe: 1]?.styleType, .night)
    }
    
    func verifyPreviewViewControllerBannerPresentationAndDismissal(for position: BannerPosition) {
        XCTAssertEqual(previewViewControllerDelegateMock.didCallWillPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallDidPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerWillDisappear, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerDidDisappear, false)
        
        let previewViewController = PreviewViewController()
        previewViewController.delegate = previewViewControllerDelegateMock
        
        let bannerConfiguration = BannerConfiguration(position: position,
                                                      height: nil)
        let banner = BannerMock(bannerConfiguration)
        
        let presentationExpectation = expectation(description: "Banner presentation expectation.")
        let animationDuration = 3.0
        previewViewController.present(banner,
                                      duration: animationDuration,
                                      completion: {
            presentationExpectation.fulfill()
        })
        
        // Right after presenting banner verify that correct methods of the delegate were called.
        XCTAssertEqual(previewViewControllerDelegateMock.didCallWillPresentBanner, true)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallDidPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerWillDisappear, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerDidDisappear, false)
        
        wait(for: [presentationExpectation], timeout: 5.0)
        
        XCTAssertEqual(previewViewControllerDelegateMock.didCallWillPresentBanner, true)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallDidPresentBanner, true)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerWillDisappear, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerDidDisappear, false)
        
        // Reset previously modified delegate properties and verify that correct delegate methods
        // are called while dismissing banner.
        previewViewControllerDelegateMock.didCallWillPresentBanner = false
        previewViewControllerDelegateMock.didCallDidPresentBanner = false
        
        let dismissalExpectation = expectation(description: "Banner dismissal expectation.")
        previewViewController.dismissBanner(at: position,
                                            duration: animationDuration,
                                            completion: {
            dismissalExpectation.fulfill()
        })
        
        // Right after dismissing banner verify that correct methods of the delegate were called.
        XCTAssertEqual(previewViewControllerDelegateMock.didCallWillPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallDidPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerWillDisappear, true)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerDidDisappear, false)
        
        wait(for: [dismissalExpectation], timeout: 5.0)
        
        XCTAssertEqual(previewViewControllerDelegateMock.didCallWillPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallDidPresentBanner, false)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerWillDisappear, true)
        XCTAssertEqual(previewViewControllerDelegateMock.didCallBannerDidDisappear, true)
    }
    
    func testPreviewViewControllerTopBannerPresentationDelegate() {
        verifyPreviewViewControllerBannerPresentationAndDismissal(for: .topLeading)
    }
    
    func testPreviewViewControllerBottomBannerPresentationDelegate() {
        verifyPreviewViewControllerBannerPresentationAndDismissal(for: .bottomLeading)
    }
}
