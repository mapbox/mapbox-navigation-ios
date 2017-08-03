import Foundation

extension String {
    var nonEmptyString: String? {
        return isEmpty ? nil : self
    }
    
    var wholeRange: NSRange {
        get {
            return NSRange(location: 0, length: characters.count)
        }
    }
}
