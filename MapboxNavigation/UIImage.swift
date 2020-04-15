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
    
    func withCenteredText(_ text: String, color: UIColor, font: UIFont, scale: CGFloat) -> UIImage {
        let maxHeight = font.lineHeight * 2
        var constrainedSize = size
        constrainedSize.width = min(constrainedSize.width, constrainedSize.width * maxHeight / constrainedSize.height)
        constrainedSize.height = min(constrainedSize.height, maxHeight)
        
        let renderer = UIGraphicsImageRenderer(size: constrainedSize)
        return renderer.image { (context) in
            let textStyle = NSMutableParagraphStyle()
            textStyle.alignment = .center
            
            let textFontAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: textStyle]
            let rect = CGRect(origin: .zero, size: constrainedSize)
            draw(in: rect)
            
            (text as NSString).draw(in: rect.offsetBy(dx: 0, dy: (constrainedSize.height - font.lineHeight) / 2).integral, withAttributes: textFontAttributes)
        }
    }
}
