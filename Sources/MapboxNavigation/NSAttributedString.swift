import UIKit

extension NSMutableAttributedString {
    
    func canonicalizeAttachments(maximumImageSize: CGSize, imageRendererFormat: UIGraphicsImageRendererFormat) {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: []) { (value, range, stop) in
            guard let attachment = value as? NSTextAttachment, type(of: attachment) != NSTextAttachment.self else {
                return
            }
            
            let sanitizedAttachment = NSTextAttachment()
            let maximumHeight = maximumImageSize.height
            if #available(iOS 11.0, *), let image = attachment.image, image.size.height > maximumHeight {
                // Scale down any oversized images.
                let size = CGSize(width: image.size.width * maximumHeight / image.size.height, height: maximumHeight)
                let resizedImage = UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { (context) in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                sanitizedAttachment.image = resizedImage
            } else {
                sanitizedAttachment.image = attachment.image
            }
            sanitizedAttachment.bounds = attachment.bounds
            setAttributes([.attachment: sanitizedAttachment], range: range)
        }
    }
}
