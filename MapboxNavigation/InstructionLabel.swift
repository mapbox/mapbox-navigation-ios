import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
@objc(MBInstructionLabel)
open class InstructionLabel: StylableLabel {
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    var shieldHeight: CGFloat = 30
    
    var instruction: [VisualInstructionComponent]? {
        didSet {
            constructInstructions()
        }
    }
    
    func constructInstructions() {
        guard let instruction = instruction else {
            text = nil
            return
        }
        
        let string = NSMutableAttributedString()
        
        // Add text or image
        for component in instruction {
            let isFirst = component == instruction.first
            let joinChar = !isFirst ? " " : ""
            
            if let shieldKey = component.shieldKey(), let _ = component.imageURL {
                if let cachedImage = component.cachedShield(shieldKey) {
                    string.append(attributedString(with: cachedImage))
                } else {
                    // Download shield and display road code in the meantime
                    if let text = component.text {
                        string.append(NSAttributedString(string: joinChar + text, attributes: attributes))
                    }
                    DispatchQueue.main.async {
                        component.shieldImage(height: self.shieldHeight, completion: { [unowned self] (image) in
                            guard image != nil, component.cachedShield(shieldKey) != nil else { return }
                            self.constructInstructions()
                        })
                    }
                }
            } else if let text = component.text {
                string.append(NSAttributedString(string: (joinChar+text).abbreviated(toFit: availableBounds(), font: font), attributes: attributes))
            }
        }
        
        attributedText = string
    }
    
    var attributes: [NSAttributedStringKey: Any] {
        return [.font: font, .foregroundColor: textColor]
    }
    
    func attributedString(with shieldImage: UIImage) -> NSAttributedString {
        let attachment = ShieldAttachment()
        attachment.font = font
        attachment.image = shieldImage
        return NSAttributedString(attachment: attachment)
    }
}

class ShieldAttachment: NSTextAttachment {
    
    var font: UIFont = UIFont.systemFont(ofSize: 17)
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let image = image else { return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)}
        let mid = font.descender + font.capHeight
        return CGRect(x: 0, y: font.descender - image.size.height / 2 + mid + 2, width: image.size.width, height: image.size.height).integral
    }
}
