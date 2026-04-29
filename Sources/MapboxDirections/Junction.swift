import Foundation

/// Contains information about routing and passing junction along the route.
public struct Junction: Codable, Equatable, Sendable {
    /// The name of the junction, if available.
    public let name: String?

    /// Initializes a new `Junction` object.
    /// - Parameters:
    ///   - name: the name of the junction.
    public init(name: String?) {
        self.name = name
    }
}
