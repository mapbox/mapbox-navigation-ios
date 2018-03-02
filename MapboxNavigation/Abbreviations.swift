import UIKit
import MapboxDirections

extension String {
    /// Returns the string abbreviated only as much as necessary to fit the given width and font.
    func abbreviated(toFit bounds: CGRect, font: UIFont, possibleAbbreviation: String?) -> String {
        let availableSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let fittedString = self
        let stringSize = fittedSize(with: availableSize, font: font)
        
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        } else if let possibleAbbreviation = possibleAbbreviation {
            return possibleAbbreviation
        } else {
            return fittedString
        }
    }
    
    func abbreviated(toFit label: InstructionLabel, component: VisualInstructionComponent) -> String {
        let bounds = label.availableBounds()
        let availableSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let fittedString = self
        let stringSize = fittedSize(with: availableSize, font: label.font)
        
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        } else if let abbreviation = component.abbreviation {
            return abbreviation
        } else {
            return fittedString
        }
    }
    
    func fittedSize(with size: CGSize, font: UIFont) -> CGSize {
        return self.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil).size
    }
}
