import Foundation

extension String {
    var ISO8601Date: Date? {
        return DateFormatter.ISO8601.date(from: self)
    }
}

extension String {
    public typealias Replacement = (of: String, with: String)
    
    public func byReplacing(_ replacements: [Replacement]) -> String {
        return replacements.reduce(self) { $0.replacingOccurrences(of: $1.of, with: $1.with) }
    }
    
    public var addingXMLEscapes: String {
        return byReplacing([
            ("&", "&amp;"),
            ("<", "&lt;"),
            ("\"", "&quot;"),
            ("'", "&apos;")
            ])
    }
    
    public var removingPunctuation: String {
        return byReplacing([
            ("(", ""),
            (")", ""),
            ("_", "")
            ])
    }
}
