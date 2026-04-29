import Foundation

/// Configures how Electronic Horizon supports live incidents on a most probable path.
///
/// To enable live incidents ``IncidentsConfig`` should be provided to ``CoreConfig/liveIncidentsConfig`` before
/// starting navigation.
public struct IncidentsConfig: Equatable, Sendable {
    /// Incidents provider graph name.
    ///
    /// If empty - incidents will be disabled.
    public var graph: String

    /// LTS incidents service API url.
    ///
    /// If `nil` is supplied will use a default url.
    public var apiURL: URL?

    /// Creates new ``IncidentsConfig``.
    /// - Parameters:
    ///   - graph: Incidents provider graph name.
    ///   - apiURL: LTS incidents service API url.
    public init(graph: String, apiURL: URL?) {
        self.graph = graph
        self.apiURL = apiURL
    }
}
