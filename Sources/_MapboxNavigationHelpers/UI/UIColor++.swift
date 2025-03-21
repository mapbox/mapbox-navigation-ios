import UIKit

extension UIColor {
    public var hexString: String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)
        guard r >= 0, r <= 1, g >= 0, g <= 1, b >= 0, b <= 1 else { return nil }

        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}

extension UIColor {
    /**
     Returns `UIImage` representation of a `UIColor`.

     - parameter size: optional size of `UIImage`. If not provided empty image will be returned.
     */
    public func image(_ size: CGSize = .zero) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
