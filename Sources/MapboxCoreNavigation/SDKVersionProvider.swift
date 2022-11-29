import Foundation

struct VersionProvider {
    enum MapboxSDK {
        case mapboxNavigation
        case mapboxCoreNavigation
    }

    private static let bundleShortVersionKey = "CFBundleShortVersionString"

    private static var cache = [MapboxSDK: String]()

    static func version(for SDK: MapboxSDK) -> String {
        if let sdkVersion = cache[SDK] {
            return sdkVersion
        }

        let sdkVersion = resolveVersion(for: SDK)
        cache[SDK] = sdkVersion

        return sdkVersion
    }

    private init() {}

    private static func resolveVersion(for SDK: MapboxSDK) -> String {
        // Checks if MBXInfo.plist exists
        if let infoDictionary = infoDictionary(for: SDK),
           let sdkVersion = infoDictionary[bundleShortVersionKey] as? String {
            return sdkVersion
        }

        // If MBXInfo.plist wasn't included, try to parse version from SDK bundle's Info.plist
        guard let SDKBundle = bundle(for: SDK) else {
            preconditionFailure("Navigation SDK bundle cannot be resvoled")
        }

        if SDKBundle === Bundle.main {
            // Looks like SDK was linked statically
            // In this case SDK version cannot be resolved without the MBXInfo.plist file
            // Check that you copy this resource to your app's bundle or link Navigation SDK dynamically
            preconditionFailure("Unable to resolve Navigation SDK version")
        } else if let sdkVersion = SDKBundle.object(forInfoDictionaryKey: bundleShortVersionKey) as? String {
            return sdkVersion
        } else {
            preconditionFailure("Navigation SDK bundles have to include CFBundleShortVersionString in Info.plist")
        }
    }
}

// MARK: - Helpers

extension VersionProvider {
    private static func bundle(for SDK: MapboxSDK) -> Bundle? {
        switch SDK {
        case .mapboxCoreNavigation:
            return .mapboxCoreNavigation
        case .mapboxNavigation:
            return .mapboxNavigationIfInstalled
        }
    }

    private static func infoDictionary(for SDK: MapboxSDK) -> [String: Any]? {
        switch SDK {
        case .mapboxCoreNavigation:
            return Bundle.mapboxCoreNavigationInfoDictionary
        case .mapboxNavigation:
            return Bundle.mapboxNavigationInfoDictionary
        }
    }
}
