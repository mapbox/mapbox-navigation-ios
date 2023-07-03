import XCTest
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class EventsMetadataProviderTests: TestCase {
    class ScreenSpy: UIScreen {
        var returnedBrightness: Float = 1

        override var brightness: CGFloat {
            set { returnedBrightness = Float(newValue) }
            get { CGFloat(returnedBrightness) }
        }
    }

    class AudioSessionInfoProviderSpy: AudioSessionInfoProvider {
        var outputVolume: Float = 1
        var telemetryAudioType: AudioType = .unknown
    }

    class ConnectivityTypeProviderSpy: ConnectivityTypeProvider {
        var connectivityType: String = ""
    }

    var provider: EventsMetadataProvider!

    var appState: EventAppState!
    var screen: ScreenSpy!
    var device: DeviceSpy!
    var audioSessionInfoProvider: AudioSessionInfoProviderSpy!
    var connectivityTypeProvider: ConnectivityTypeProviderSpy!

    override func setUp() {
        super.setUp()

        screen = ScreenSpy()
        screen.brightness = 0.5
        device = DeviceSpy()
        device.returnedOrientation = .landscapeLeft
        let environment = EventAppState.Environment(date: { Date() },
                                                    applicationState: { .active },
                                                    screenOrientation: { .landscapeLeft },
                                                    deviceOrientation: { .faceUp })
        appState = EventAppState(environment: environment)
        audioSessionInfoProvider = AudioSessionInfoProviderSpy()
        connectivityTypeProvider = ConnectivityTypeProviderSpy()
        
        provider = EventsMetadataProvider(appState: appState,
                                          screen: screen,
                                          audioSessionInfoProvider: audioSessionInfoProvider,
                                          device: device,
                                          connectivityTypeProvider: connectivityTypeProvider)
    }

    func testReturnVolumeLevel() {
        XCTAssertEqual(provider.provideEventsMetadata().volumeLevel, 100)

        audioSessionInfoProvider.outputVolume = 0.5
        XCTAssertEqual(provider.provideEventsMetadata().volumeLevel, 50)

        audioSessionInfoProvider.outputVolume = 0
        XCTAssertEqual(provider.provideEventsMetadata().volumeLevel, 0)
    }

    func testReturnBatteryLevel() {
        XCTAssertEqual(provider.provideEventsMetadata().batteryLevel, 100)

        device.returnedBatteryLevel = 0.5
        XCTAssertEqual(provider.provideEventsMetadata().batteryLevel, 50)

        device.returnedBatteryLevel = 0
        XCTAssertEqual(provider.provideEventsMetadata().batteryLevel, 0)

        device.returnedBatteryLevel = -1
        XCTAssertNil(provider.provideEventsMetadata().batteryLevel)
    }

    func testReturnBatteryPluggedIn() {
        device.returnedBatteryState = .unplugged
        XCTAssertEqual(provider.provideEventsMetadata().batteryPluggedIn, false)

        device.returnedBatteryState = .unknown
        XCTAssertEqual(provider.provideEventsMetadata().batteryPluggedIn, false)

        device.returnedBatteryState = .full
        XCTAssertEqual(provider.provideEventsMetadata().batteryPluggedIn, true)

        device.returnedBatteryState = .charging
        XCTAssertEqual(provider.provideEventsMetadata().batteryPluggedIn, true)
    }

    func testReturnAppMetadata() {
        provider.userInfo = nil
        XCTAssertNil(provider.provideEventsMetadata().appMetadata)

        provider.userInfo = ["name" : "App Name"]
        XCTAssertNil(provider.provideEventsMetadata().appMetadata)

        provider.userInfo = ["version" : "App Version"]
        XCTAssertNil(provider.provideEventsMetadata().appMetadata)

        provider.userInfo = ["name" : "App Name", "version" : "App Version"]
        let appMetadata1 = provider.provideEventsMetadata().appMetadata
        XCTAssertEqual(appMetadata1?.name, "App Name")
        XCTAssertEqual(appMetadata1?.version, "App Version")
        XCTAssertNil(appMetadata1?.sessionId)
        XCTAssertNil(appMetadata1?.userId)

        provider.userInfo = [
            "name" : "App Name",
            "version" : "App Version",
            "userId": "User ID",
            "sessionId": "Session ID"]
        let appMetadata2 = provider.provideEventsMetadata().appMetadata
        XCTAssertEqual(appMetadata2?.name, "App Name")
        XCTAssertEqual(appMetadata2?.version, "App Version")
        XCTAssertEqual(appMetadata2?.userId, "User ID")
        XCTAssertEqual(appMetadata2?.sessionId, "Session ID")
    }

    func testReturnScreenBrightness() {
        screen.returnedBrightness = 1
        XCTAssertEqual(provider.provideEventsMetadata().screenBrightness, 100)

        screen.returnedBrightness = 0.5
        XCTAssertEqual(provider.provideEventsMetadata().screenBrightness, 50)

        screen.returnedBrightness = 0
        XCTAssertEqual(provider.provideEventsMetadata().screenBrightness, 0)
    }

    func testReturnPercentTimeInForeground() {
        XCTAssertEqual(provider.provideEventsMetadata().percentTimeInForeground, 100)
    }

    func testReturnPercentTimeInPortrait() {
        XCTAssertEqual(provider.provideEventsMetadata().percentTimeInPortrait, 0)
    }

    func testReturnAudioType() {
        audioSessionInfoProvider.telemetryAudioType = .bluetooth
        XCTAssertEqual(provider.provideEventsMetadata().audioType, 0)

        audioSessionInfoProvider.telemetryAudioType = .headphones
        XCTAssertEqual(provider.provideEventsMetadata().audioType, 1)

        audioSessionInfoProvider.telemetryAudioType = .speaker
        XCTAssertEqual(provider.provideEventsMetadata().audioType, 2)

        audioSessionInfoProvider.telemetryAudioType = .unknown
        XCTAssertEqual(provider.provideEventsMetadata().audioType, 3)
    }

    func testReturnConnectivity() {
        let type = "type"
        connectivityTypeProvider.connectivityType = type
        XCTAssertEqual(provider.provideEventsMetadata().connectivity, type)
    }
}
