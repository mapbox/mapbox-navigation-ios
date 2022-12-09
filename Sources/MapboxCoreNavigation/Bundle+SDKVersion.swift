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

    static func checkForNavigationSDKUpdates() {
#if targetEnvironment(simulator)
        guard (NSClassFromString("XCTestCase") == nil) else { return }
        let currentVersion = Bundle.navigationSDKVersion
        let latestVersionURL = URL(string: "https://docs.mapbox.com/ios/navigation/latest_version.txt")!
        URLSession.shared.dataTask(with: latestVersionURL, completionHandler: { (data, response, error) in
            guard error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let data = data,
                  let latestVersion = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
            else { return }

            if latestVersion != currentVersion {
                let updateString = NSLocalizedString("UPDATE_AVAILABLE", bundle: .mapboxCoreNavigation,
                                                     value: "Mapbox Navigation SDK for iOS version %@ is now available.",
                                                     comment: "Inform developer an update is available")
                let warningMessage = String.localizedStringWithFormat(updateString, latestVersion) +
                    " https://github.com/mapbox/mapbox-navigation-ios/releases/tag/v\(latestVersion)"
                Log.warning(warningMessage, category: .settings)
            }
        }).resume()
#endif
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
            preconditionFailure(
                "Unable to resolve Navigation SDK version, looks like it was linked statically. " +
                "In this case SDK version cannot be resolved without the MBXInfo.plist file. " +
                "Check that you copy this resource to your app's bundle or link Navigation SDK dynamically."
            )
        }

        if let sdkVersion = SDKBundle.object(forInfoDictionaryKey: bundleShortVersionKey) as? String {
            return sdkVersion
        } else {
            preconditionFailure("Navigation SDK bundles have to include CFBundleShortVersionString in Info.plist")
        }
    }
}
