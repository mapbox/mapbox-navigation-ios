
import Foundation

/**
 Configures how Electronic Horizon supports live incidents on a most probable path.
 
 To enable live incidents `IncidentsOptions` should be provided to `NavigationSettings` before starting navigation.
 */
public struct IncidentsOptions {
    /**
     Incidents provider graph name.
     
     If empty - incidents will be disabled.
     */
    public var graph: String
    /**
     LTS incidents service API url.
     
     If `nil` is supplied will use a default url.
     */
    public var apiURL: URL?
    
    /**
     Creates new `IncidentsOptions`
     */
    public init(graph: String, apiURL: URL?) {
        self.graph = graph
        self.apiURL = apiURL
    }
}
