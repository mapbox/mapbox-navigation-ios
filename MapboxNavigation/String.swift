import Foundation

extension String {
    var ISO8601Date: Date? {
        return Date.ISO8601Formatter.date(from: self)
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
    
    var isUppercased: Bool {
        return self == uppercased() && self != lowercased()
    }
    
    var containsDecimalDigit: Bool {
        return self.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }
}
