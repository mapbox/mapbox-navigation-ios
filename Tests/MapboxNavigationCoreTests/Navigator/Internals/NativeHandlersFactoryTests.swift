
@testable import MapboxNavigationCore
@testable import MapboxNavigationNative
import XCTest

private final class ConfigFactorySpy: ConfigFactory {
    static var passedProfile: SettingsProfile?
    static var passedConfig: NavigatorConfig?
    static var passedCustomConfig: String?

    override class func build(
        for profile: SettingsProfile,
        config: NavigatorConfig,
        customConfig: String
    ) -> ConfigHandle {
        passedProfile = profile
        passedConfig = config
        passedCustomConfig = customConfig
        return super.build(for: profile, config: config, customConfig: customConfig)
    }
}

final class NativeHandlersFactoryTests: XCTestCase {
    var factory: NativeHandlersFactory!
    var locale: Locale!

    let defaultConfig: [String: Any] = [
        "features": [
            "useInternalReroute": true,
            "useInternalRouteRefresh": true,
            "useTelemetryNavigationEvents": true,
        ],
        "navigation": [
            "alternativeRoutes": [
                "dropDistance": [
                    "maxSlightFork": 50.0,
                ],
            ],
        ],
    ]

    override func setUp() {
        super.setUp()

        factory = nativeHandlersFactory()
        locale = Locale(identifier: "en-US")
        factory.locale = locale
    }

    func testSpecifyDefaultCustomConfig() {
        let defaultCustomConfigData = try! JSONSerialization.data(withJSONObject: defaultConfig, options: [.sortedKeys])
        let defaultCustomConfig = String(data: defaultCustomConfigData, encoding: .utf8)!
        _ = factory.configHandle(by: ConfigFactorySpy.self)

        let customConfig = ConfigFactorySpy.passedCustomConfig!
        XCTAssertEqual(customConfig, defaultCustomConfig)
    }

    func testMergeCustomConfig() {
        let userCustomConfig: [String: Any] = [
            "features": [
                "useInternalReroute": false,
                "custom_new_key": true,
            ],
            "custom": "a",
        ]
        UserDefaults.standard.set(userCustomConfig, forKey: customConfigKey)

        var expectedConfig = defaultConfig
        expectedConfig["custom"] = "a"
        expectedConfig["features"] = [
            "useInternalReroute": true,
            "useInternalRouteRefresh": true,
            "useTelemetryNavigationEvents": true,
            "custom_new_key": true,
        ]
        let expectedCustomConfigData = try! JSONSerialization.data(
            withJSONObject: expectedConfig,
            options: [.sortedKeys]
        )
        let expectedCustomConfig = String(data: expectedCustomConfigData, encoding: .utf8)!
        _ = factory.configHandle(by: ConfigFactorySpy.self)

        let customConfig = ConfigFactorySpy.passedCustomConfig!
        XCTAssertEqual(customConfig, expectedCustomConfig)
        UserDefaults.standard.set(nil, forKey: customConfigKey)
    }

    func testCreateConfigHandleSettings() {
        let configHandle = factory.configHandle(by: ConfigFactorySpy.self)
        let settings = configHandle.mutableSettings()
        XCTAssertEqual(settings.userLanguages(), locale.preferredBCP47Codes)
        XCTAssertEqual(settings.avoidManeuverSeconds(), NSNumber(value: factory.initialManeuverAvoidanceRadius))
    }

    func testCreateNavigatorConfig() {
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        let navigatorConfig = ConfigFactorySpy.passedConfig!
        XCTAssertNil(navigatorConfig.voiceInstructionThreshold)
        XCTAssertNil(navigatorConfig.electronicHorizonOptions)
        XCTAssertNil(navigatorConfig.noSignalSimulationEnabled)
        XCTAssertEqual(navigatorConfig.useSensors, NSNumber(value: true))
    }

    func testConfigurePollingIfNilNavigatorPredictionInterval() {
        factory = nativeHandlersFactory(navigatorPredictionInterval: nil)
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        let navigatorConfig = ConfigFactorySpy.passedConfig!
        XCTAssertNil(navigatorConfig.polling)
    }

    func testConfigurePollingIfNonNilNavigatorPredictionInterval() {
        let predictionInterval: TimeInterval = 10
        factory = nativeHandlersFactory(navigatorPredictionInterval: predictionInterval)
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        let polling = ConfigFactorySpy.passedConfig!.polling
        XCTAssertEqual(polling?.lookAhead, NSNumber(value: predictionInterval))
        XCTAssertNil(polling?.unconditionalPatience)
        XCTAssertNil(polling?.unconditionalInterval)
    }

    func testConfigurePollingIfNonNilStatusUpdatingSettings() {
        let predictionInterval: TimeInterval = 10
        let settings = StatusUpdatingSettings(
            updatingPatience: 10,
            updatingInterval: 100
        )
        factory = nativeHandlersFactory(
            navigatorPredictionInterval: predictionInterval,
            statusUpdatingSettings: settings
        )
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        let polling = ConfigFactorySpy.passedConfig!.polling
        XCTAssertEqual(polling?.lookAhead, NSNumber(value: predictionInterval))
        XCTAssertEqual(polling?.unconditionalPatience, NSNumber(value: settings.updatingPatience!))
        XCTAssertEqual(polling?.unconditionalInterval, NSNumber(value: settings.updatingInterval!))
    }

    func testConfigureNilIncidentsOptions() {
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        XCTAssertNil(ConfigFactorySpy.passedConfig!.incidentsOptions)
    }

    func testConfigureNilIncidentsOptionsIfEmptyGraph() {
        let incidentsOptions = IncidentsConfig(graph: "", apiURL: URL(string: "string"))
        factory = nativeHandlersFactory(liveIncidentsOptions: incidentsOptions)
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        XCTAssertNil(ConfigFactorySpy.passedConfig!.incidentsOptions)
    }

    func testConfigureNonNilIncidentsOptions() {
        let incidentsOptions = IncidentsConfig(graph: "graph", apiURL: URL(string: "string"))
        factory = nativeHandlersFactory(liveIncidentsOptions: incidentsOptions)
        _ = factory.configHandle(by: ConfigFactorySpy.self)
        let nativeIncidentsOptions = ConfigFactorySpy.passedConfig!.incidentsOptions
        XCTAssertEqual(nativeIncidentsOptions?.graph, incidentsOptions.graph)
        XCTAssertEqual(nativeIncidentsOptions?.apiUrl, incidentsOptions.apiURL?.absoluteString)
    }

    private func nativeHandlersFactory(
        liveIncidentsOptions: IncidentsConfig? = nil,
        navigatorPredictionInterval: TimeInterval? = nil,
        statusUpdatingSettings: StatusUpdatingSettings? = nil
    ) -> NativeHandlersFactory {
        NativeHandlersFactory(
            tileStorePath: "",
            apiConfiguration: .mock(),
            tilesVersion: "",
            datasetProfileIdentifier: .automobile,
            liveIncidentsOptions: liveIncidentsOptions,
            navigatorPredictionInterval: navigatorPredictionInterval,
            statusUpdatingSettings: statusUpdatingSettings,
            utilizeSensorData: true,
            historyDirectoryURL: nil,
            initialManeuverAvoidanceRadius: 12,
            locale: .current
        )
    }
}
