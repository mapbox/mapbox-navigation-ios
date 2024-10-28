import MapboxNavigationNative

extension ConfigHandle {
    public static func mock(
        settingsProfile: SettingsProfile = .mock(),
        config: NavigatorConfig = .mock(),
        customConfig: String = ""
    ) -> ConfigHandle {
        ConfigFactory.build(
            for: settingsProfile,
            config: config,
            customConfig: customConfig
        )
    }
}
