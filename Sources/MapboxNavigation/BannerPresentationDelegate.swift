import Foundation

protocol BannerPresentationDelegate: AnyObject {

    func bannerWillAppear(_ presenter: BannerPresentation,
                          banner: Banner)

    func bannerDidAppear(_ presenter: BannerPresentation,
                         banner: Banner)

    func bannerWillDisappear(_ presenter: BannerPresentation,
                             banner: Banner)

    func bannerDidDisappear(_ presenter: BannerPresentation,
                            banner: Banner)
}
