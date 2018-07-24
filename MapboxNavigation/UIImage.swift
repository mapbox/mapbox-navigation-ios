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
    
    func composited(text: NSString, color: UIColor, font: UIFont, atPoint: CGPoint, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        
        let textFontAttributes: [NSAttributedStringKey: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: textStyle]
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let rect = CGRect(x: atPoint.x, y: atPoint.y, width: size.width, height: size.height)
        text.draw(in: rect.integral, withAttributes: textFontAttributes)
        
        let compositedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compositedImage
    }
}
