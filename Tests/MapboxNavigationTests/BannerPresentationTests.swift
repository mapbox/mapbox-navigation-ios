import XCTest
import TestHelper
@testable import MapboxNavigation

class BannerPresentationDelegateMock: BannerPresentationDelegate {
    
    var didCallBannerWillAppear = false
    var didCallBannerDidAppear = false
    var didCallBannerWillDisappear = false
    var didCallBannerDidDisappear = false
    
    func bannerWillAppear(_ presenter: BannerPresentation,
                          banner: Banner) {
        didCallBannerWillAppear = true
    }
    
    func bannerDidAppear(_ presenter: BannerPresentation,
                         banner: Banner) {
        didCallBannerDidAppear = true
    }
    
    func bannerWillDisappear(_ presenter: BannerPresentation,
                             banner: Banner) {
        didCallBannerWillDisappear = true
    }
    
    func bannerDidDisappear(_ presenter: BannerPresentation,
                            banner: Banner) {
        didCallBannerDidDisappear = true
    }
}

class BannerPresentationMock: UIViewController, BannerPresentation {
    
    var navigationView: NavigationView = NavigationView(frame: .zero)
    
    var bannerPresentationDelegate: BannerPresentationDelegate? = nil
    
    var topBanners = Stack<Banner>()
    
    var bottomBanners = Stack<Banner>()
}

class BannerMock: UIViewController, Banner {
    
    var bannerConfiguration: BannerConfiguration
    
    init(_ bannerConfiguration: BannerConfiguration) {
        self.bannerConfiguration = bannerConfiguration
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BannerPresentationTests: TestCase {
    
    var bannerPresentationDelegateMock: BannerPresentationDelegateMock!
    
    override func setUpWithError() throws {
        bannerPresentationDelegateMock = BannerPresentationDelegateMock()
    }
    
    func testTopAndBottomBannerPresentation() {
        let bannerPresenter = BannerPresentationMock()
        XCTAssertNil(bannerPresenter.topBanners.peek())
        XCTAssertNil(bannerPresenter.bottomBanners.peek())
        
        let topBannerConfiguration = BannerConfiguration(position: .topLeading,
                                                         height: nil)
        let topBanner = BannerMock(topBannerConfiguration)
        bannerPresenter.push(topBanner)
        
        // Check if banner is correctly pushed to the top postion, stack that contains bottom banners
        // should remain empty.
        var topmostTopBanner = bannerPresenter.topmostTopBanner as? BannerMock
        XCTAssertEqual(topmostTopBanner, topBanner)
        
        var topmostBottomBanner = bannerPresenter.topmostBottomBanner as? BannerMock
        XCTAssertEqual(topmostBottomBanner, nil)
        
        // Do similar check, but using different method.
        topmostTopBanner = bannerPresenter.topBanner(at: .topLeading) as? BannerMock
        XCTAssertEqual(topmostTopBanner, topBanner)
        
        topmostBottomBanner = bannerPresenter.topBanner(at: .bottomLeading) as? BannerMock
        XCTAssertEqual(topmostBottomBanner, nil)
        
        // Pop top banner and verify that it's correctly popped.
        let poppedBanner = bannerPresenter.popBanner(at: .topLeading) as? BannerMock
        XCTAssertEqual(poppedBanner, topBanner)
        
        topmostTopBanner = bannerPresenter.topBanner(at: .topLeading) as? BannerMock
        XCTAssertEqual(topmostTopBanner, nil)
        
        // Push bottom banner and verify that it's present.
        let bottomBannerConfiguration = BannerConfiguration(position: .bottomLeading,
                                                            height: 100.0)
        let bottomBanner = BannerMock(bottomBannerConfiguration)
        bannerPresenter.push(bottomBanner)
        
        topmostTopBanner = bannerPresenter.topBanner(at: .topLeading) as? BannerMock
        XCTAssertEqual(topmostTopBanner, nil)
        
        topmostBottomBanner = bannerPresenter.topBanner(at: .bottomLeading) as? BannerMock
        XCTAssertEqual(topmostBottomBanner, bottomBanner)
    }
    
    func verifyBannerPresentationAndDismissal(for position: BannerPosition) {
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillDisappear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidDisappear, false)
        
        let bannerPresenter = BannerPresentationMock()
        bannerPresenter.bannerPresentationDelegate = bannerPresentationDelegateMock
        
        let bannerConfiguration = BannerConfiguration(position: position,
                                                      height: nil)
        let banner = BannerMock(bannerConfiguration)
        
        let presentationExpectation = expectation(description: "Banner presentation expectation.")
        let animationDuration = 3.0
        bannerPresenter.push(banner,
                             duration: animationDuration,
                             completion: {
            presentationExpectation.fulfill()
        })
        
        // Right after presenting banner verify that correct methods of the delegate were called.
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillAppear, true)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillDisappear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidDisappear, false)
        
        wait(for: [presentationExpectation], timeout: 5.0)
        
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillAppear, true)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidAppear, true)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillDisappear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidDisappear, false)
        
        // Reset previously modified delegate properties and verify that correct delegate methods
        // are called while dismissing banner.
        bannerPresentationDelegateMock.didCallBannerWillAppear = false
        bannerPresentationDelegateMock.didCallBannerDidAppear = false
        
        let dismissalExpectation = expectation(description: "Banner dismissal expectation.")
        bannerPresenter.popBanner(at: position,
                                  duration: animationDuration,
                                  completion: {
            dismissalExpectation.fulfill()
        })
        
        // Right after dismissing banner verify that correct methods of the delegate were called.
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillDisappear, true)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidDisappear, false)
        
        wait(for: [dismissalExpectation], timeout: 5.0)
        
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidAppear, false)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerWillDisappear, true)
        XCTAssertEqual(bannerPresentationDelegateMock.didCallBannerDidDisappear, true)
    }
    
    func testTopBannerPresentationDelegate() {
        verifyBannerPresentationAndDismissal(for: .topLeading)
    }
    
    func testBottomBannerPresentationDelegate() {
        verifyBannerPresentationAndDismissal(for: .bottomLeading)
    }
}
