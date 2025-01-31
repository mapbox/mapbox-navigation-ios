import UIKit

public class DeviceSpy: UIDevice {
    public var returnedOrientation: UIDeviceOrientation
    public var returnedBatteryLevel: Float
    public var returnedBatteryState: UIDevice.BatteryState

    override public var orientation: UIDeviceOrientation {
        returnedOrientation
    }

    override public var batteryLevel: Float {
        returnedBatteryLevel
    }

    override public var batteryState: UIDevice.BatteryState {
        returnedBatteryState
    }

    public init(
        returnedOrientation: UIDeviceOrientation = .portrait,
        returnedBatteryLevel: Float = 1,
        returnedBatteryState: UIDevice.BatteryState = .unplugged
    ) {
        self.returnedOrientation = returnedOrientation
        self.returnedBatteryLevel = returnedBatteryLevel
        self.returnedBatteryState = returnedBatteryState
    }
}
