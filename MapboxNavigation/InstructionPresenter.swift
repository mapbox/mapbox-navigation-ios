import UIKit
import MapboxDirections

class InstructionPresenter {
    private let instruction: [VisualInstructionComponent]
    private weak var label: InstructionLabel?

    required init(_ instruction: [VisualInstructionComponent], label: InstructionLabel) {
        self.instruction = instruction
        self.label = label
    }

    typealias ShieldDownloadCompletion = (NSAttributedString) -> ()
    var onShieldDownload: ShieldDownloadCompletion?

    private let imageRepository = ImageRepository.shared

    func attributedText() -> NSAttributedString {
        guard let label = self.label else {
            return NSAttributedString()
        }

        let string = NSMutableAttributedString()

        for component in instruction {
            let isFirst = component == instruction.first
            let joinChar = !isFirst ? " " : ""

            if let shieldKey = component.shieldKey() {
                if let cachedImage = imageRepository.cachedImageForKey(shieldKey) {
                    string.append(NSAttributedString(string: joinChar))
                    string.append(attributedString(withFont: label.font, shieldImage: cachedImage))
                } else {
                    // Display road code while shield is downloaded
                    if let text = component.text {
                        string.append(NSAttributedString(string: joinChar + text, attributes: attributesForLabel(label)))
                    }
                    shieldImageForComponent(component, height: label.shieldHeight, completion: { [weak self] (image) in
                        guard image != nil else {
                            return
                        }
                        if let strongSelf = self, let completion = strongSelf.onShieldDownload {
                            completion(strongSelf.attributedText())
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

    private func shieldImageForComponent(_ component: VisualInstructionComponent, height: CGFloat, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = component.imageURL, let shieldKey = component.shieldKey() else {
            return
        }

        imageRepository.imageWithURL(imageURL, cacheKey: shieldKey, completion: { (image) in
            completion(image)
        })
    }

    private func instructionHasDownloadedAllShields() -> Bool {
        for component in instruction {
            guard let key = component.shieldKey() else {
                continue
            }

            if imageRepository.cachedImageForKey(key) == nil {
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
