import Foundation

/// Struct for decoding / encoding 'simple' values which can't be standalone decoded / encoded
/// because they're not valid JSON, e.g. enums, strings. numbers etc.
struct CodableContainer<C: Codable>: Codable {
    let wrapped: C
}
