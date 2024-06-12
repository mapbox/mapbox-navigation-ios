import Foundation

/// Contains information about routing and passing interchange along the route.
public struct Interchange: Codable, Equatable, Sendable {
    /// The name of the interchange, if available.
    public let name: String?

    /// Initializes a new `Interchange` object.
    /// - Parameters:
    ///   - name: the name of the interchange.
    public init(name: String?) {
        self.name = name
    }
}
