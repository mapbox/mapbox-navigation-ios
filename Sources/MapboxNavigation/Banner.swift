import UIKit

// :nodoc:
public protocol Banner: UIViewController {
    
    var bannerConfiguration: BannerConfiguration { get }
}

// :nodoc:
public struct BannerConfiguration {
    
    // :nodoc:
    public private(set) var position: BannerPosition = .bottomLeading
    
    // :nodoc:
    public private(set) var height: CGFloat? = nil
    
    // :nodoc:
    public private(set) var isExpandable: Bool = false
    
    // :nodoc:
    public private(set) var expansionOffset: CGFloat = 0.0
    
    // :nodoc:
    public init(position: BannerPosition,
                height: CGFloat? = nil,
                isExpandable: Bool = false,
                expansionOffset: CGFloat = 0.0) {
        self.position = position
        self.height = height
        self.isExpandable = isExpandable
        self.expansionOffset = expansionOffset
    }
}
