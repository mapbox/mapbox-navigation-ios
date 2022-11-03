import UIKit

/**
 A banner protocol provides the ability to show content inside `NavigationView`. Components that
 conform to `Banner` protocol must be instances of the `UIViewController`. Banners are injected
 into `BannerContainerView` and can have various properties: can be shown at the top or at the
 bottom of the screen, can be expanded and collapsed and can have custom height.
 
 By default Mapbox Navigation SDK provides several default banners:
 - `DestinationPreviewViewController` - banner that is shown at the bottom of the screen and allows
 to show information about the final destination, preview available routes and start active navigation
 session
 - `RoutePreviewViewController` - banner that is shown at the bottom of the screen and allows to
 preview information about the current `Route` (expected travel time, distance and expected time of arrival)
 - `BannerDismissalViewController` - banner that is shown at the top of the screen and allows to
 dismiss already presented banner
 */
public protocol Banner: UIViewController {
    
    /**
     Configuration of the banner.
     */
    var bannerConfiguration: BannerConfiguration { get }
}

/**
 Configuration of the banner that allows to change its default behavior.
 */
public struct BannerConfiguration {
    
    /**
     Position of the `Banner`. `Banner` is presented at the bottom of the screen by default.
     */
    public private(set) var position: BannerPosition = .bottomLeading
    
    /**
     Initial height of the `Banner` in points.
     */
    public private(set) var height: CGFloat? = nil
    
    /**
     A Boolean value that determines whether `Banner` can be expanded or not. Defaults to `false`.
     Presented `Banner` is collapsed by default.
     */
    public private(set) var isExpandable: Bool = false
    
    /**
     A floating-point value that denotes extent by which `Banner` can be expanded. Defaults to `0.0`.
     Presented `Banner` is collapsed by default.
     */
    public private(set) var expansionOffset: CGFloat = 0.0
    
    /**
     Initializes a new `BannerConfiguration` object.
     
     - parameter position: Position of the `Banner`.
     - parameter height: Initial height of the `Banner` in points.
     - parameter isExpandable: A Boolean value that determines whether `Banner` can be expanded or not.
     - parameter expansionOffset: A floating-point value that denotes extent by which `Banner`
     can be expanded.
     */
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
