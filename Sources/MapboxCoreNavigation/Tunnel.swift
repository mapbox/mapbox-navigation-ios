
import Foundation
import MapboxNavigationNative

/**
 `Tunnel` is used for naming incoming tunnels, together with route alerts.
 */
public struct Tunnel {
    /**
     The name of the tunnel.
     */
    public let name: String?
    
    init(_ tunnelInfo: TunnelInfo) {
        name = tunnelInfo.name
    }
}
