import _MapboxNavigationHelpers
import Foundation
import Network

protocol ConnectivityTypeProvider {
    var connectivityType: String { get }
}

protocol NetworkMonitor: AnyObject, Sendable {
    func start(queue: DispatchQueue)
    var pathUpdateHandler: (@Sendable (_ newPath: NWPath) -> Void)? { get set }
}

protocol NetworkPath {
    var status: NWPath.Status { get }
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool
}

extension NWPathMonitor: NetworkMonitor {}
extension NWPath: NetworkPath {}
extension NWPathMonitor: @unchecked Sendable {}

final class MonitorConnectivityTypeProvider: ConnectivityTypeProvider, Sendable {
    private let monitor: NetworkMonitor
    private let monitorConnectionType = UnfairLocked<NWInterface.InterfaceType?>(nil)
    private let queue = DispatchQueue.global(qos: .utility)

    private static let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]

    var connectivityType: String {
        monitorConnectionType.read()?.connectionType ?? "No Connection"
    }

    init(monitor: NetworkMonitor = NWPathMonitor()) {
        self.monitor = monitor

        configureMonitor()
    }

    func handleChange(to path: NetworkPath) {
        let newMonitorConnectionType: NWInterface.InterfaceType?
        if path.status == .satisfied {
            let connectionTypes = MonitorConnectivityTypeProvider.connectionTypes
            newMonitorConnectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other
        } else {
            newMonitorConnectionType = nil
        }
        monitorConnectionType.update(newMonitorConnectionType)
    }

    private func configureMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handleChange(to: path)
        }
        monitor.start(queue: queue)
    }
}

extension NWInterface.InterfaceType {
    fileprivate var connectionType: String {
        switch self {
        case .cellular:
            return "Cellular"
        case .wifi:
            return "WiFi"
        case .wiredEthernet:
            return "Wired"
        case .loopback, .other:
            return "Unknown"
        @unknown default:
            Log.warning("Unexpected NWInterface.InterfaceType type", category: .settings)
            return "Unexpected"
        }
    }
}
