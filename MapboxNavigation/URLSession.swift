import Foundation
import MapboxDirections

extension URLSession {
    /// The user agent string for any HTTP requests performed directly within this library.
    static let userAgent: String = {
        var components: [String] = []
        
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String {
            let version = Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? ""
            components.append("\(appName)/\(version)")
        }
        
        let libraryBundle: Bundle? = Bundle(for: ImageDownloader.self)
        
        if let libraryName = libraryBundle?.object(forInfoDictionaryKey: "CFBundleName") as? String, let navVersion = libraryBundle?.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String {
            components.append("\(libraryName)/\(navVersion)")
        }
        
        let directionsLibraryBundle: Bundle? = Bundle(for: Directions.self)
        
        if let directionsLibraryName = directionsLibraryBundle?.object(forInfoDictionaryKey: "CFBundleName") as? String, let directionsVersion = directionsLibraryBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            components.append("\(directionsLibraryName)/\(directionsVersion)")
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
        components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")
        
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
        components.append("(\(chip))")
        
        return components.joined(separator: " ")
    }()
    
}
