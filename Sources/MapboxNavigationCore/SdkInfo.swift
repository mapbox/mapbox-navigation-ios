import MapboxCommon_Private

public struct SdkInfo: Sendable {
    public static let navigationUX: Self = .init(
        name: Bundle.resolvedNavigationSDKName,
        version: Bundle.mapboxNavigationVersion,
        packageName: "com.mapbox.navigationUX"
    )

    public static let navigationCore: Self = .init(
        name: Bundle.navigationCoreName,
        version: Bundle.mapboxNavigationVersion,
        packageName: "com.mapbox.navigationCore"
    )

    public let name: String
    public let version: String
    public let packageName: String

    var native: SdkInformation {
        .init(name: name, version: version, packageName: packageName)
    }
}
