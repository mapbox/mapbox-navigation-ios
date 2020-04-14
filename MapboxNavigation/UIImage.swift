import Foundation

extension UIImage {
    public func roundedWithBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let square = CGSize(width: min(size.width, size.height) + width * 3, height: min(size.width, size.height) + width * 3)
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .center
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = width
        imageView.layer.backgroundColor = color.cgColor
        imageView.layer.borderColor = color.cgColor
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func insert(text: NSString, color: UIColor, font: UIFont, scale: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            let textStyle = NSMutableParagraphStyle()
            textStyle.alignment = .center
            
            let textFontAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: textStyle]
            let rect = CGRect(origin: .zero, size: size)
            draw(in: rect)
            
            text.draw(in: rect.offsetBy(dx: 0, dy: (size.height - font.lineHeight) / 2).integral, withAttributes: textFontAttributes)
        }
    }
}
