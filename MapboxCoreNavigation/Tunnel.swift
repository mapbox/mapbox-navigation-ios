
import Foundation
import MapboxNavigationNative

/**
 `Tunnel` is used for naming incoming tunnels, together with route alerts.
 */
public struct Tunnel {
    public let name: String
    
    init(_ tunnelInfo: RouteAlertTunnelInfo) {
        name = tunnelInfo.name
    }
}
