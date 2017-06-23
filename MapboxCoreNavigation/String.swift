import UIKit

extension String {
    static var systemName: String {
        #if os(iOS) || os(tvOS)
            return UIDevice.current.systemName
        #elseif os(watchOS)
            return WKInterfaceDevice.current.systemVersion
        #elseif os(OSX)
            return "macOS"
        #else
            return "unknown"
        #endif
    }
    
    static var systemVersion: String {
        let versionObject = ProcessInfo().operatingSystemVersion
        return "\(versionObject.majorVersion).\(versionObject.minorVersion).\(versionObject.patchVersion)"
    }
}
