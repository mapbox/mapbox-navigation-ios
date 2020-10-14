
import Foundation
import MapboxNavigationNative

/**
 `TunnelInfo` is used for naming incoming tunnels, together with route alerts.
 */
public struct TunnelInfo {
    public let name: String
    
    init(_ tunnelInfo: RouteAlertTunnelInfo) {
        name = tunnelInfo.name
    }
}
