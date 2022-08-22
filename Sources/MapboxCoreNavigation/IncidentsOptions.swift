
import Foundation

/**
 Electronic Horizon supports live incidents on a most probable path. To enable live incidents `IncidentsOptions` should be provided to `NavigationSettings` before starting navigation. If both `graph` and `apiUrl` are empty, live incidents are disabled (by default).
 */
public struct IncidentsOptions {
    /**
     Incidents provider graph name.
     */
    public var graph: String
    /**
     LTS incidents service API url.
     
     If `nil` is supplied will use a default url.
     */
    public var apiURL: URL?
}
