import UIKit

public class DeviceSpy: UIDevice {
    public var returnedOrientation: UIDeviceOrientation = .portrait
    public var returnedBatteryLevel: Float = 1
    public var returnedBatteryState: UIDevice.BatteryState = .unplugged

    public override var orientation: UIDeviceOrientation {
        returnedOrientation
    }

    public override var batteryLevel: Float {
        returnedBatteryLevel
    }

    public override var batteryState: UIDevice.BatteryState {
        returnedBatteryState
    }
}
