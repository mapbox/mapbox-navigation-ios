import XCTest
import MapboxNavigationNative
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

private let customConfigKey = "com.mapbox.navigation.custom-config"

class ConfigFactorySpy: ConfigFactory {
    
    static var passedCustomConfig: String?
    
    override class func build(for profile: SettingsProfile,
                              config: NavigatorConfig,
                              customConfig: String) -> ConfigHandle {
        passedCustomConfig = customConfig
        return super.build(for: profile, config: config, customConfig: customConfig)
    }
}

class NativeHandlersFactoryTests: TestCase {
    
    var handlersFactory: NativeHandlersFactory!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.set(nil, forKey: customConfigKey)
    }

    override func tearDown() {
        UserDefaults.resetStandardUserDefaults()
        super.tearDown()
    }
    
    func testDefaultCustomConfig() {
        let expectedCustomConfig = [
            "features": [
                "useInternalReroute": true
            ]
        ]
        _ = NativeHandlersFactory.configHandle(by: ConfigFactorySpy.self)
        let config = customConfig(from: ConfigFactorySpy.passedCustomConfig)
        XCTAssertTrue(config == expectedCustomConfig)
    }
    
    func testCustomConfigFromUserDefatuls() {
        UserDefaults.standard.set([
            "features": [
                "custom_feature_key": "custom_feature_value"
            ]
        ], forKey: customConfigKey)
        let expectedCustomConfig = [
            "features": [
                "custom_feature_key": "custom_feature_value",
                "useInternalReroute": true
            ]
        ]
        _ = NativeHandlersFactory.configHandle(by: ConfigFactorySpy.self)
        let config = customConfig(from: ConfigFactorySpy.passedCustomConfig)
        XCTAssertTrue(config == expectedCustomConfig)
    }
    
    func testUserDefaultsOverwritesDefaultCustomConfig() {
        UserDefaults.standard.set([
            "features": [
                "historyAutorecording": false
            ]
        ], forKey: customConfigKey)
        let expectedCustomConfig = [
            "features": [
                "historyAutorecording": false,
                "useInternalReroute": true
            ]
        ]
        _ = NativeHandlersFactory.configHandle(by: ConfigFactorySpy.self)
        let config = customConfig(from: ConfigFactorySpy.passedCustomConfig)
        XCTAssertTrue(config == expectedCustomConfig)
    }
    
    // MARK: Helpers
    
    private func customConfig(from string: String?) -> [String: Any] {
        let stringData = string?.data(using: .utf8) ?? Data()
        let config = try? JSONSerialization.jsonObject(with: stringData, options: []) as? [String: Any]
        return config ?? [:]
    }
}
