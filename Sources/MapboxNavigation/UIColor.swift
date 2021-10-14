import UIKit

extension UIColor {

    /**
     Returns `UIImage` representation of a `UIColor`.
     
     - parameter size: optional size of `UIImage`. If not provided empty image will be returned.
     */
    func image(_ size: CGSize = .zero) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
