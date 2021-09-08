import Foundation
import MapboxDirections

extension URLSession {
    /**
     :nodoc:
     
     The user agent string for any HTTP requests performed directly within MapboxCoreNavigation or MapboxNavigation.
     */
    public static let userAgent: String = {
        // Bundles in order from the application level on down
        #if SWIFT_PACKAGE
        let bundles: [Bundle?] = [
            .main,
            .mapboxNavigationIfInstalled,
            .mapboxCoreNavigation
        ]
        #else
        let bundles: [Bundle?] = [
            .main,
            .mapboxNavigationIfInstalled,
            .mapboxCoreNavigation,
            .init(for: Directions.self),
        ]
        #endif

        let bundleComponents = bundles.compactMap { (bundle) -> String? in
            guard let name = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String ?? bundle?.bundleIdentifier else { return nil }
            
            let defaultMapboxNavigationBundleName = "MapboxNavigation"
            let defaultMapboxCoreNavigationBundleName = "MapboxCoreNavigation"
            
            #if SWIFT_PACKAGE
            let mapboxNavigationName = "MapboxNavigation_MapboxNavigation"
            #else
            let mapboxNavigationName = defaultMapboxNavigationBundleName
            #endif

            #if SWIFT_PACKAGE
            let mapboxCoreNavigationName = "MapboxNavigation_MapboxCoreNavigation"
            #else
            let mapboxCoreNavigationName = defaultMapboxCoreNavigationBundleName
            #endif
            
            var bundleName: String {
                switch name {
                case mapboxNavigationName:
                    return defaultMapboxNavigationBundleName
                case mapboxCoreNavigationName:
                    return defaultMapboxCoreNavigationBundleName
                default:
                    return name
                }
            }
            
            var stringForShortVersion: String? {
                switch name {
                case mapboxNavigationName:
                    return Bundle.string(forMapboxNavigationInfoDictionaryKey: "CFBundleShortVersionString")
                case mapboxCoreNavigationName:
                    return Bundle.string(forMapboxCoreNavigationInfoDictionaryKey: "CFBundleShortVersionString")
                default:
                    return bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                }
            }
            guard let version = stringForShortVersion else { return nil }
            return "\(bundleName)/\(version)"
        }

        let system: String
        #if os(OSX)
        system = "macOS"
        #elseif os(iOS)
        system = "iOS"
        #elseif os(watchOS)
        system = "watchOS"
        #elseif os(tvOS)
        system = "tvOS"
        #elseif os(Linux)
        system = "Linux"
        #endif
        let systemVersion = ProcessInfo().operatingSystemVersion
        let systemComponent = "\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"

        let chip: String
        #if arch(x86_64)
        chip = "x86_64"
        #elseif arch(arm)
        chip = "arm"
        #elseif arch(arm64)
        chip = "arm64"
        #elseif arch(i386)
        chip = "i386"
        #endif
        let chipComponent = "(\(chip))"
        
        let components: [String] = bundleComponents + [
            systemComponent,
            chipComponent,
        ]
        return components.joined(separator: " ")
    }()
}
