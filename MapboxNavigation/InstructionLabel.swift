import UIKit
import MapboxCoreNavigation

/// :nodoc:
@objc(MBInstructionLabel)
open class InstructionLabel: StylableLabel {
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    var shieldHeight: CGFloat = 30
    
    var instruction: Instruction? {
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
        for component in instruction.components {
            let isFirst = component == instruction.components.first
            let joinChar = !isFirst ? " " : ""
            
            if let prefix = component.prefix {
                string.append(NSAttributedString(string: prefix, attributes: attributes))
            }
            
            if let roadCode = component.roadCode, let network = component.network, let number = component.number {
                // Check if shield image is cached, otherwise display road code in text
                let shieldKey = UIImage.shieldKey(network, number: number, height: shieldHeight)
                if let cachedImage = UIImage.cachedShield(shieldKey) {
                    string.append(attributedString(with: cachedImage))
                    if let direction = component.direction {
                        string.append(NSAttributedString(string: " "+direction, attributes: attributes))
                    }
                } else {
                    // Download shield and display road code in the meantime
                    string.append(NSAttributedString(string: joinChar+roadCode, attributes: attributes))
                    UIImage.shieldImage(network, number: number, height: shieldHeight, completion: { [unowned self] (image) in
                        // Reconstruct instructions if we did get a shield image
                        guard image != nil, UIImage.cachedShield(shieldKey) != nil else { return }
                        self.constructInstructions()
                    })
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
