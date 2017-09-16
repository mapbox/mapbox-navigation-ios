import Foundation

extension String {
    var ISO8601Date: Date? {
        return DateFormatter.ISO8601.date(from: self)
    }
    
    /**
     Check if the current string is empty. If the string is empty, `nil` is returned, otherwise, the string is returned.
     */
    public var nonEmptyString: String? {
        return isEmpty ? nil : self
    }
    
    var wholeRange: Range<String.Index> {
        return startIndex..<endIndex
    }
    
    typealias Replacement = (of: String, with: String)
    
    func byReplacing(_ replacements: [Replacement]) -> String {
        return replacements.reduce(self) { $0.replacingOccurrences(of: $1.of, with: $1.with) }
    }
    
    var addingXMLEscapes: String {
        return byReplacing([
            ("&", "&amp;"),
            ("<", "&lt;"),
            ("\"", "&quot;"),
            ("'", "&apos;")
            ])
    }
    
    var removingPunctuation: String {
        return byReplacing([
            ("(", ""),
            (")", ""),
            ("_", "")
            ])
    }
    
    var asSSMLAddress: String {
        return "<say-as interpret-as=\"address\">\(self.addingXMLEscapes)</say-as>"
    }
    
    var asSSMLCharacters: String {
        return "<say-as interpret-as=\"characters\">\(self.addingXMLEscapes)</say-as>"
    }
    
    func withSSMLPhoneme(ipaNotation: String) -> String {
        return "<phoneme alphabet=\"ipa\" ph=\"\(ipaNotation.addingXMLEscapes)\">\(self.addingXMLEscapes)</phoneme>"
    }
    
    var isUppercased: Bool {
        return self == uppercased() && self != lowercased()
    }
    
    var containsDecimalDigit: Bool {
        return self.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }
}
