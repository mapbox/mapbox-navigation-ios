#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif

extension ProcessInfo {
    static var systemName: String {
        #if os(iOS) || os(tvOS)
            return UIDevice.current.systemName
        #elseif os(watchOS)
            return WKInterfaceDevice.current.systemName
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
