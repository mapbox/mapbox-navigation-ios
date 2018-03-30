import Foundation

extension Sequence where Element: Hashable {
    func compatibleFlatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        #if swift(>=4.1)
            return try compactMap(transform)
        #else
            return try flatMap(transform)
        #endif
    }
}
