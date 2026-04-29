import MapboxNavigationNative_Private

extension SettingsProfile {
    public static func mock(
        application: ProfileApplication = .mobile,
        platform: ProfilePlatform = .IOS
    ) -> SettingsProfile {
        SettingsProfile(application: application, platform: platform)
    }
}
