import UIKit

let path = Bundle.mapboxNavigation.path(forResource: "Abbreviations", ofType: "plist")!
let allAbbrevations = NSDictionary(contentsOfFile: path) as? [String: [String: String]]

/// Options that specify what kinds of words in a string should be abbreviated.
struct StringAbbreviationOptions: OptionSet {
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
        var abbreviatedString = self
        abbreviatedString.enumerateSubstrings(in: abbreviatedString.wholeRange, options: [.byWords, .reverse]) { (substring, substringRange, enclosingRange, stop) in
            guard var word = substring?.lowercased() else {
                return
            }
            
            if let abbreviation = allAbbrevations!["abbreviations"]![word], options.contains(.Abbreviations) {
                word = abbreviation
            } else if let direction = allAbbrevations!["directions"]![word], options.contains(.Directions) {
                word = direction
            } else if let classification = allAbbrevations!["classifications"]![word], options.contains(.Classifications) {
                word = classification
            } else {
                return
            }
            
            abbreviatedString.replaceSubrange(substringRange, with: word)
        }
        return abbreviatedString
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
        return self.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil).size
    }
}
