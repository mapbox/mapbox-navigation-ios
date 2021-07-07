import XCTest
import MapboxNavigationNative
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

class NativeHandlersFactoryTests: XCTestCase {
    
    var handlersFactory: NativeHandlersFactory!
    
    override func setUp() {
        UserDefaults.standard.set(nil, forKey: customConfigKey)
        handlersFactory = NativeHandlersFactory(tileStorePath: "tile store path",
                                                configFactoryType: ConfigFactorySpy.self)
    }
    
    func testDefaultCustomConfig() {
        let expectedCustomConfig = customConfig(from: [
            "features": [
                "historyAutorecording": true
            ]
        ])
        _ = handlersFactory.configHandle
        XCTAssertEqual(ConfigFactorySpy.passedCustomConfig, expectedCustomConfig)
    }
    
    func testCustomConfigFromUserDefatuls() {
        UserDefaults.standard.set([
            "features": [
                "custom_feature_key": "custom_feature_value"
            ]
        ], forKey: customConfigKey)
        let expectedCustomConfig = customConfig(from: [
            "features": [
                "historyAutorecording": true,
                "custom_feature_key": "custom_feature_value"
            ]
        ])
        _ = handlersFactory.configHandle
        XCTAssertEqual(ConfigFactorySpy.passedCustomConfig, expectedCustomConfig)
    }
    
    func testUserDefaultsOverwritesDefaultCustomConfig() {
        UserDefaults.standard.set([
            "features": [
                "historyAutorecording": false
            ]
        ], forKey: customConfigKey)
        let expectedCustomConfig = customConfig(from: [
            "features": [
                "historyAutorecording": false
            ]
        ])
        _ = handlersFactory.configHandle
        XCTAssertEqual(ConfigFactorySpy.passedCustomConfig, expectedCustomConfig)
    }
    
    // MARK: Helpers
    
    private func customConfig(from dictionary: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: dictionary, options: [])) ?? Data()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
