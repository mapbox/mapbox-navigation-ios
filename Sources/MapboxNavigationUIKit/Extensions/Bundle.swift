import UIKit

extension Bundle {
    // MARK: Accessing Mapbox-Specific Bundles

    /// The Mapbox Navigation framework bundle.
    public class var mapboxNavigation: Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        let frameworkBundle = Bundle(for: NavigationViewController.self)

        guard let resourceBundleURL = frameworkBundle.url(
            forResource: "MapboxNavigationResources", withExtension: "bundle"
        )
        else {
            return frameworkBundle
        }

        guard let resourceBundle = Bundle(url: resourceBundleURL)
        else { fatalError("Cannot access MapboxNavigationResources.bundle!") }

        return resourceBundle
#endif
    }

    /// Returns `UIImage` by searching for it in the current `Bundle` instance.
    /// - Parameter named: Name of the image.
    /// - Returns: `UIImage` instance if image was found, `nil` otherwise.
    func image(named: String) -> UIImage? {
        return UIImage(named: named, in: self, compatibleWith: nil)
    }
}
