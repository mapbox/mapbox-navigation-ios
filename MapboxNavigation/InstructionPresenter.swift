import UIKit
import MapboxDirections

class InstructionPresenter {
    var instruction: [VisualInstructionComponent]?

    typealias ShieldDownloadCompletion = (NSAttributedString) -> ()
    var onShieldDownload: ShieldDownloadCompletion?

    func attributedTextForLabel(_ label: InstructionLabel) -> NSAttributedString {
        guard let instruction = instruction else {
            return NSAttributedString()
        }

        let string = NSMutableAttributedString()

        // Add text or image
        for component in instruction {
            let isFirst = component == instruction.first
            let joinChar = !isFirst ? " " : ""

            if let shieldKey = component.shieldKey() {
                if let cachedImage = component.cachedShield(shieldKey) {
                    string.append(attributedString(withFont: label.font, shieldImage: cachedImage))
                } else {
                    // Download shield and display road code in the meantime
                    if let text = component.text {
                        string.append(NSAttributedString(string: joinChar + text, attributes: attributesForLabel(label)))
                    }
                    component.shieldImage(height: label.shieldHeight, completion: { [unowned self] (image) in
                        guard image != nil, component.cachedShield(shieldKey) != nil else {
                            return
                        }
                        if let completion = self.onShieldDownload {
                            completion(self.attributedTextForLabel(label))
                        }
                    })
                }
            } else if let text = component.text {
                if component.type == .delimiter && instructionHasDownloadedAllShields() {
                    continue
                }
                string.append(NSAttributedString(string: (joinChar + text).abbreviated(toFit: label.availableBounds(), font: label.font), attributes: attributesForLabel(label)))
            }
        }

        return string
    }

    private func instructionHasDownloadedAllShields() -> Bool {
        for component in instruction! {
            guard let key = component.shieldKey() else {
                continue
            }

            if component.cachedShield(key) == nil {
                return false
            }
        }
        return true
    }

    private func attributesForLabel(_ label: UILabel) -> [NSAttributedStringKey: Any] {
        return [.font: label.font, .foregroundColor: label.textColor]
    }

    private func attributedString(withFont font: UIFont, shieldImage: UIImage) -> NSAttributedString {
        let attachment = ShieldAttachment()
        attachment.font = font
        attachment.image = shieldImage
        return NSAttributedString(attachment: attachment)
    }

}

class ShieldAttachment: NSTextAttachment {

    var font: UIFont = UIFont.systemFont(ofSize: 17)

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let image = image else {
            return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }
        let mid = font.descender + font.capHeight
        return CGRect(x: 0, y: font.descender - image.size.height / 2 + mid + 2, width: image.size.width, height: image.size.height).integral
    }
}
