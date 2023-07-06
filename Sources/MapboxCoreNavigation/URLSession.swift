import Foundation
import MapboxDirections
import UIKit

extension URLSession {
    /**
     :nodoc:
     
     The user agent string for any HTTP requests performed directly within MapboxCoreNavigation or MapboxNavigation.
     */
    public static let userAgent: String = {
        var bundleComponents: [String] = [
            mainBundleUserAgentFragment,
            navigationSdkCoreUserAgentFragment,
        ]
        if Bundle.usesDefaultUserInterface {
            bundleComponents.append(navigationSdkUserAgentFragment)
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
        
        var simulator: String? = nil
        if UIDevice.isSimulator {
            simulator = "Simulator"
        }
        
        let otherComponents = [
            chip,
            simulator
        ].compactMap({ $0 })
        
        let components = bundleComponents + [
            systemComponent,
            "(\(otherComponents.joined(separator: "; ")))"
        ]
        
        return components.joined(separator: " ")
    }()

    internal static let navigationSdkCoreUserAgentFragment: String = {
        "\(Bundle.navigationSdkCoreIdentifier)/\(Bundle.navigationSDKVersion)"
    }()

    internal static let navigationSdkUserAgentFragment: String = {
        "\(Bundle.navigationSdkIdentifier)/\(Bundle.navigationSDKVersion)"
    }()

    internal static let navigationSdkUserAgentFragmentForTelemetry: String = {
        if Bundle.usesDefaultUserInterface {
            return navigationSdkUserAgentFragment
        } else {
            return navigationSdkCoreUserAgentFragment
        }
    }()

    internal static let navigationSdkIdentifierForTelemetry: String = {
        if Bundle.usesDefaultUserInterface {
            return Bundle.navigationSdkIdentifier
        } else {
            return Bundle.navigationSdkCoreIdentifier
        }
    }()

    internal static let mainBundleUserAgentFragment: String = {
        let bundle = Bundle.main
        let name = bundle.bundleName
        let version = bundle.bundleShortVersion
        return "\(bundle.bundleName)/\(bundle.bundleShortVersion ?? "n/a")"
    }()
}
