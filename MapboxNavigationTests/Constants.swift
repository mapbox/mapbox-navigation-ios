import XCTest

extension CGSize {
    static let iPhone5      : CGSize    = CGSize(width: 320, height: 568)
    static let iPhone6Plus  : CGSize    = CGSize(width: 414, height: 736)
    static let iPhoneX      : CGSize    = CGSize(width: 375, height: 812)
}

struct ShieldImage {
    let image: UIImage
    let url: URL
}

extension ShieldImage {
    static let i280 = ShieldImage(image: UIImage(named: "i-280", in: Bundle(for: InstructionsBannerViewIntegrationTests.self), compatibleWith: nil)!,
                                  url: URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/i-280@3x.png")!)
    static let us101 = ShieldImage(image: UIImage(named: "us-101", in: Bundle(for: InstructionsBannerViewIntegrationTests.self), compatibleWith: nil)!,
                                   url: URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/us-101@3x.png")!)
}
