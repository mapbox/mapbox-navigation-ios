import Foundation

extension UIImage {
    func tinted(_ tintColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        tintColor.set()
        draw(in: CGRect(origin: .zero, size: size))
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
}
