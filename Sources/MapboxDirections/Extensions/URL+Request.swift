import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URL {
    init(path: String, host: URL) {
        guard let url = URL(string: path, relativeTo: host) else {
            assertionFailure("Cannot form valid URL from '\(path)' relative to '\(host)'")
            self = host
            return
        }
        self = url
    }
}

extension URLRequest {
    mutating func setupUserAgentString() {
        setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }
}

/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []

    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main
        .infoDictionary?["CFBundleIdentifier"] as? String
    {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }

    let libraryBundle: Bundle? = Bundle(for: Directions.self)

    if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String,
       let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String
    {
        components.append("\(libraryName)/\(version)")
    }

    // `ProcessInfo().operatingSystemVersionString` can replace this when swift-corelibs-foundaton is next released:
    // https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/ProcessInfo.swift#L104-L202
    let system: String
#if os(macOS)
    system = "macOS"
#elseif os(iOS)
    system = "iOS"
#elseif os(watchOS)
    system = "watchOS"
#elseif os(tvOS)
    system = "tvOS"
#elseif os(Linux)
    system = "Linux"
#else
    system = "unknown"
#endif
    let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
    components
        .append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")

    let chip: String
#if arch(x86_64)
    chip = "x86_64"
#elseif arch(arm)
    chip = "arm"
#elseif arch(arm64)
    chip = "arm64"
#elseif arch(i386)
    chip = "i386"
#else
    // Maybe fall back on `uname(2).machine`?
    chip = "unrecognized"
#endif

    var simulator: String?
#if targetEnvironment(simulator)
    simulator = "Simulator"
#endif

    let otherComponents = [
        chip,
        simulator,
    ].compactMap { $0 }

    components.append("(\(otherComponents.joined(separator: "; ")))")

    return components.joined(separator: " ")
}()
