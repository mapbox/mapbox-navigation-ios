import UIKit

public class DeviceSpy: UIDevice {
    public var returnedOrientation: UIDeviceOrientation = .portrait
    public var returnedBatteryLevel: Float = 1
    public var returnedBatteryState: UIDevice.BatteryState = .unplugged

    override public var orientation: UIDeviceOrientation {
        returnedOrientation
    }

    override public var batteryLevel: Float {
        returnedBatteryLevel
    }

    override public var batteryState: UIDevice.BatteryState {
        returnedBatteryState
    }
}
