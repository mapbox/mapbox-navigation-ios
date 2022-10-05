import UIKit

// :nodoc:
public protocol BannerPreviewing: UIViewController {
    
    var configuration: PreviewBannerConfiguration { get }
}

// :nodoc:
public struct PreviewBannerConfiguration {
    
    // :nodoc:
    public var position: Banner.Position = .bottomLeading
    
    // :nodoc:
    public var height: CGFloat? = nil
    
    // :nodoc:
    public init(position: Banner.Position, height: CGFloat? = nil) {
        self.position = position
        self.height = height
    }
}
