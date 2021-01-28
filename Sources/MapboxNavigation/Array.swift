import Foundation

extension Array {
    /**
     Conditionally remove each element depending on the elements immediately preceding and following it.
     
     - parameter shouldBeRemoved: A closure that is called once for each element in reverse order from last to first. The closure accepts the following arguments: the preceding element in the (unreversed) array, the element itself, and the following element in the (unreversed) array.
     */
    mutating func removeSeparators(where shouldBeRemoved: (Element?, Element, Element?) throws -> Bool) rethrows {
        for (index, element) in enumerated().reversed() {
            let precedingElement = lazy.prefix(upTo: index).last
            let followingElement = lazy.suffix(from: self.index(after: index)).first
            if try shouldBeRemoved(precedingElement, element, followingElement) {
                remove(at: index)
            }
        }
    }
}

extension Array where Element: NSAttributedString {
    /**
     Returns a new attributed string by concatenating the elements of the array, adding the given separator between each element.
     */
    func joined(separator: NSAttributedString = .init()) -> NSAttributedString {
        guard let first = first else {
            return NSAttributedString()
        }
        
        let joinedAttributedString = NSMutableAttributedString(attributedString: first)
        for element in dropFirst() {
            joinedAttributedString.append(separator)
            joinedAttributedString.append(element)
        }
        return joinedAttributedString
    }
}
