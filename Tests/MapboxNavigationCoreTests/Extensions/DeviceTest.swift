import _MapboxNavigationTestHelpers
@testable import MapboxNavigationCore
import XCTest

final class DeviceTest: XCTestCase {
    var device: DeviceSpy!

    override func setUp() {
        super.setUp()
        device = DeviceSpy()
    }

    func testScreenOrientation() {
        device.returnedOrientation = .portrait
        XCTAssertEqual(device.screenOrientation, .portrait)

        device.returnedOrientation = .portraitUpsideDown
        XCTAssertEqual(device.screenOrientation, .portraitUpsideDown)

        device.returnedOrientation = .landscapeLeft
        XCTAssertEqual(device.screenOrientation, .landscapeLeft)

        device.returnedOrientation = .landscapeRight
        XCTAssertEqual(device.screenOrientation, .landscapeRight)

        device.returnedOrientation = .faceUp
        XCTAssertNotEqual(device.screenOrientation, .faceUp)
    }
}
