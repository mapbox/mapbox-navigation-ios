import Foundation
import MapboxDirections

extension URLSession {
    /**
     :nodoc:
     
     The user agent string for any HTTP requests performed directly within MapboxCoreNavigation or MapboxNavigation.
     */
    public static let userAgent: String = {
        let bundles: [Bundle?] = [
            // Bundles in order from the application level on down
            .main,
            .mapboxNavigationIfInstalled,
            .mapboxCoreNavigation,
            .init(for: Directions.self),
        ]
        let bundleComponents = bundles.compactMap { (bundle) -> String? in
            guard let name = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String ?? bundle?.bundleIdentifier,
                let version = bundle?.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String else {
                return nil
            }
            return "\(name)/\(version)"
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
