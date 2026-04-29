import Foundation

extension Collection {
    /// Returns an index set containing the indices that satisfy the given predicate.
    func indices(where predicate: (Element) throws -> Bool) rethrows -> IndexSet {
        return try IndexSet(enumerated().filter { try predicate($0.element) }.map(\.offset))
    }
}
