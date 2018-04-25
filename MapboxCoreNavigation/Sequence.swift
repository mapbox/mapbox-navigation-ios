import Foundation

extension Sequence where Element: Hashable {
    #if !swift(>=4.1)
    func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        return try flatMap(transform)
    }
    #endif
}
