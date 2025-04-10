import UIKit

@_spi(MapboxInternal)
extension UIFont {
    public class var defaultRouteAnnotationTextFont: UIFont {
        .systemFont(ofSize: 18, weight: .semibold)
    }

    public class var defaultRouteAnnotationCaptionTextFont: UIFont {
        .systemFont(ofSize: 16, weight: .regular)
    }
}
