import XCTest
@testable import MapboxNavigation

class BannerPresentationDelegateMock: BannerPresentationDelegate {
    
    func bannerWillAppear(_ presenter: MapboxNavigation.BannerPresentation,
                          banner: MapboxNavigation.Banner) {
        
    }
    
    func bannerDidAppear(_ presenter: MapboxNavigation.BannerPresentation,
                         banner: MapboxNavigation.Banner) {
        
    }
    
    func bannerWillDisappear(_ presenter: MapboxNavigation.BannerPresentation,
                             banner: MapboxNavigation.Banner) {
        
    }
    
    func bannerDidDisappear(_ presenter: MapboxNavigation.BannerPresentation,
                            banner: MapboxNavigation.Banner) {
        
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

final class BannerPresentationTests: XCTestCase {
    
    override func setUpWithError() throws {
        
    }
    
    override func tearDownWithError() throws {
        
    }
    
    func testBannerPresentation() {
        let bannerPresenter = BannerPresentationMock()
        XCTAssertNil(bannerPresenter.topBanners.peek())
        XCTAssertNil(bannerPresenter.bottomBanners.peek())
        
        let bannerConfiguration = BannerConfiguration(position: .topLeading, height: nil)
        let banner = BannerMock(bannerConfiguration)
        bannerPresenter.push(banner)
    }
}
