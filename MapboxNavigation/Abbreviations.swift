import UIKit

let path = Bundle.mapboxNavigation.path(forResource: "Abbreviations", ofType: "plist")!
let allAbbrevations = NSDictionary(contentsOfFile: path) as? [String: [String: String]]

/// Options that specify what kinds of words in a string should be abbreviated.
struct StringAbbreviationOptions : OptionSet {
    let rawValue: Int
    
    /// Abbreviates ordinary words that have common abbreviations.
    static let Abbreviations = StringAbbreviationOptions(rawValue: 1 << 0)
    /// Abbreviates directional words.
    static let Directions = StringAbbreviationOptions(rawValue: 1 << 1)
    /// Abbreviates road name suffixes.
    static let Classifications = StringAbbreviationOptions(rawValue: 1 << 2)
}

extension String {
    /// Returns an abbreviated copy of the string.
    func abbreviated(by options: StringAbbreviationOptions) -> String {
        return characters.split(separator: " ").map(String.init).map { (word) -> String in
            let lowercaseWord = word.lowercased()
            if let abbreviation = allAbbrevations!["abbreviations"]![lowercaseWord], options.contains(.Abbreviations) {
                return abbreviation
            }
            if let direction = allAbbrevations!["directions"]![lowercaseWord], options.contains(.Directions) {
                return direction
            }
            if let classification = allAbbrevations!["classifications"]![lowercaseWord], options.contains(.Classifications) {
                return classification
            }
            return word
            }.joined(separator: " ")
    }
    
    /// Returns the string abbreviated only as much as necessary to fit the given width and font.
    func abbreviated(toFit bounds: CGRect, font: UIFont) -> String {
        let availableSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        var fittedString = self
        var stringSize = fittedSize(with: availableSize, font: font)
        
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        }
        
        fittedString = fittedString.abbreviated(by: [.Classifications])
        stringSize = fittedString.fittedSize(with: availableSize, font: font)
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        }
        
        fittedString = fittedString.abbreviated(by: [.Directions])
        stringSize = fittedString.fittedSize(with: availableSize, font: font)
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        }
        
        return fittedString.abbreviated(by: [.Abbreviations])
    }
    
    func fittedSize(with size: CGSize, font: UIFont) -> CGSize {
        return self.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSFontAttributeName: font], context: nil).size
    }
}
