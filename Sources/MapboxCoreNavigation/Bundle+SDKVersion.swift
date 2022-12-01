import Foundation

extension Bundle {
    private static let bundleShortVersionKey = "CFBundleShortVersionString"

    private static var cachedNavigationSDKVersion: String?
    static var navigationSDKVersion: String {
        if let sdkVersion = cachedNavigationSDKVersion {
            return sdkVersion
        }

        let sdkVersion = resolveNavigationSDKVersion()
        cachedNavigationSDKVersion = sdkVersion

        return sdkVersion
    }

    private static func resolveNavigationSDKVersion() -> String {
        // Checks if MBXInfo.plist exists
        if let infoDictionary = Bundle.mapboxCoreNavigationInfoDictionary ?? Bundle.mapboxNavigationInfoDictionary,
           let sdkVersion = infoDictionary[bundleShortVersionKey] as? String {
            return sdkVersion
        }

        // If MBXInfo.plist wasn't included, try to parse version from SDK bundle's Info.plist
        let navigationBundles: [Bundle] = [.mapboxCoreNavigation, .mapboxNavigationIfInstalled].compactMap { $0 }

        guard let SDKBundle = navigationBundles.first(where: { $0 !== Bundle.main }) else {
            // Looks like SDK was linked statically
            // In this case SDK version cannot be resolved without the MBXInfo.plist file
            // Check that you copy this resource to your app's bundle or link Navigation SDK dynamically
            preconditionFailure("Unable to resolve Navigation SDK version")
        }

        if let sdkVersion = SDKBundle.object(forInfoDictionaryKey: bundleShortVersionKey) as? String {
            return sdkVersion
        } else {
            preconditionFailure("Navigation SDK bundles have to include CFBundleShortVersionString in Info.plist")
        }
    }
}
