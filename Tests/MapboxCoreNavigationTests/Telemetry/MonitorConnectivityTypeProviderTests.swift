import XCTest
import TestHelper
import Network
@testable import MapboxCoreNavigation

final class MonitorConnectivityTypeProviderTests: TestCase {
    var connectivityTypeProvider: MonitorConnectivityTypeProvider!
    var monitor: NWPathMonitorSpy!

    class NWPathMonitorSpy: NetworkMonitor {
        var startCalled = false

        var pathUpdateHandler: ((NWPath) -> Void)?

        func start(queue: DispatchQueue) {
            startCalled = true
        }
    }

    struct NetworkPathSpy: NetworkPath {
        var status: NWPath.Status = .unsatisfied
        var usedInterfaceTypes: Set<NWInterface.InterfaceType> = .init()

        func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
            usedInterfaceTypes.contains(type)
        }
    }

    override func setUp() {
        super.setUp()

        monitor = NWPathMonitorSpy()
        connectivityTypeProvider = MonitorConnectivityTypeProvider(monitor: monitor)
    }

    func testStartsMonitorInInit() {
        XCTAssertTrue(monitor.startCalled)
    }

    func testReturnCellularConnectivity() {
        let path = NetworkPathSpy(status: .satisfied, usedInterfaceTypes: [.cellular])
        connectivityTypeProvider.handleChange(to: path)
        XCTAssertEqual(connectivityTypeProvider.connectivityType, "Cellular")
    }

    func testReturnWiFiConnectivity() {
        let path = NetworkPathSpy(status: .satisfied, usedInterfaceTypes: [.wifi])
        connectivityTypeProvider.handleChange(to: path)
        XCTAssertEqual(connectivityTypeProvider.connectivityType, "WiFi")
    }

    func testReturnWiredConnectivity() {
        let path = NetworkPathSpy(status: .satisfied, usedInterfaceTypes: [.wiredEthernet])
        connectivityTypeProvider.handleChange(to: path)
        XCTAssertEqual(connectivityTypeProvider.connectivityType, "Wired")
    }

    func testReturnUnknownConnectivity() {
        let path = NetworkPathSpy(status: .satisfied, usedInterfaceTypes: [.other, .loopback])
        connectivityTypeProvider.handleChange(to: path)
        XCTAssertEqual(connectivityTypeProvider.connectivityType, "Unknown")
    }

    func testReturnNoConnectivity() {
        let path1 = NetworkPathSpy(status: .unsatisfied)
        connectivityTypeProvider.handleChange(to: path1)
        XCTAssertEqual(connectivityTypeProvider.connectivityType, "No Connection")

        let path2 = NetworkPathSpy(status: .requiresConnection)
        connectivityTypeProvider.handleChange(to: path2)
        XCTAssertEqual(connectivityTypeProvider.connectivityType, "No Connection")
    }

}
