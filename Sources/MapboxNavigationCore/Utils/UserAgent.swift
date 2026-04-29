import Foundation
import MapboxCommon_Private

extension URLRequest {
    public mutating func setNavigationUXUserAgent() {
        setValue(.navigationUXUserAgent, forHTTPHeaderField: "User-Agent")
    }
}

extension String {
    public static let navigationUXUserAgent: String = {
        let processInfo = ProcessInfo()
        let systemVersion = processInfo.operatingSystemVersion
        let version = [
            systemVersion.majorVersion,
            systemVersion.minorVersion,
            systemVersion.patchVersion,
        ].map(String.init).joined(separator: ".")
        let system = processInfo.system()

        let systemComponent = [system, version].joined(separator: "/")

#if targetEnvironment(simulator)
        var simulator: String? = "Simulator"
#else
        var simulator: String?
#endif

        let otherComponents = [
            processInfo.chip(),
            simulator,
        ].compactMap { $0 }

        let mainBundleId = Bundle.main.bundleIdentifier ?? Bundle.main.bundleURL.lastPathComponent

        let components = [
            "\(mainBundleId)/\(Bundle.main.version ?? "unknown")",
            navigationUXUserAgentFragment,
            systemComponent,
            "(\(otherComponents.joined(separator: "; ")))",
        ]
        let userAgent = components.joined(separator: " ")
        Log.info("UserAgent: \(userAgent)", category: .settings)
        return userAgent
    }()

    public static let navigationUXUserAgentFragment: String =
        "\(Bundle.resolvedNavigationSDKName)/\(Bundle.mapboxNavigationVersion)"
}

extension Bundle {
    public static let navigationUXName: String = "mapbox-navigationUX-ios"
    public static let navigationUIKitName: String = "mapbox-navigationUIKit-ios"
    public static let navigationCoreName: String = "mapbox-navigationCore-ios"
    /// Deduced SDK name.
    ///
    /// Equals ``navigationCoreName``, ``navigationUIKitName`` or ``navigationUXName``, based on the detected project
    /// dependencies structure.
    public static var resolvedNavigationSDKName: String {
        if NSClassFromString("MapboxNavigationUX.NavigationUX") != nil {
            navigationUXName
        } else if NSClassFromString("MapboxNavigationUIKit.NavigationViewController") != nil {
            navigationUIKitName
        } else {
            navigationCoreName
        }
    }

    var version: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

extension ProcessInfo {
    fileprivate func chip() -> String {
#if arch(x86_64)
        "x86_64"
#elseif arch(arm)
        "arm"
#elseif arch(arm64)
        "arm64"
#elseif arch(i386)
        "i386"
#endif
    }

    fileprivate func system() -> String {
#if os(OSX)
        "macOS"
#elseif os(iOS)
        "iOS"
#elseif os(watchOS)
        "watchOS"
#elseif os(tvOS)
        "tvOS"
#elseif os(Linux)
        "Linux"
#endif
    }
}
