import Foundation

extension NSAttributedString {
    static func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(left)
        result.append(right)
        return result
    }
}

extension NSMutableAttributedString {
    func canonicalizeAttachments() {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: []) { (value, range, stop) in
            guard let attachment = value as? NSTextAttachment, type(of: attachment) != NSTextAttachment.self else {
                return
            }
            
            let sanitizedAttachment = NSTextAttachment()
            sanitizedAttachment.image = attachment.image
            sanitizedAttachment.bounds = attachment.bounds
            setAttributes([.attachment: sanitizedAttachment], range: range)
        }
    }
}
