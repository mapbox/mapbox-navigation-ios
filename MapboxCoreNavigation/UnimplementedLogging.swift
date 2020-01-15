import Foundation
import os.log
import Dispatch

/**
 Protocols that provide no-op default method implementations can use this protocol to log a message to the console whenever an unimplemented delegate method is called.
 
 In Swift, optional protocol methods exist only for Objective-C compatibility. However, various protocols in this library follow a classic Objective-C delegate pattern in which the protocol would have a number of optional methods. Instead of the disallowed `optional` keyword, these protocols conform to the `UnimplementedLogging` protocol to inform about unimplemented methods at runtime. These console messages are logged to the subsystem `com.mapbox.com` with a category of the format “delegation.<var>ProtocolName</var>”, where <var>ProtocolName</var> is the name of the protocol that defines the method.
 
 The default method implementations should be provided as part of the protocol or an extension thereof. If the default implementations reside in an extension, the extension should have the same visibility level as the protocol itself.
 */
public protocol UnimplementedLogging {
    /**
     Prints a warning to standard output.
     */
    func logUnimplemented(protocolType: Any, level: OSLogType, function: String)
}

public extension UnimplementedLogging {
    func logUnimplemented(protocolType: Any, level: OSLogType, function: String = #function) {
        
        let protocolDescription = String(describing: protocolType)
        let selfDescription = String(describing: type(of: self))
        
        let description = (selfDescription, function)

        let alreadyWarned = warned.contains { elem -> Bool in
            elem == description
        }
        
        guard !alreadyWarned else {
            return
        }
        
        let log = OSLog(subsystem: "com.mapbox.navigation", category: "delegation.\(selfDescription)")
        let formatted: StaticString = "Unimplemented delegate method in %@: %@.%@. This message will only be logged once."
        os_log(formatted, log: log, type: level, selfDescription, protocolDescription, function)
        unimplementedTestLogs?.append((selfDescription, function))
        warned.append(description)
    }
}

fileprivate var warned: [(String, String)] = []


var unimplementedTestLogs: [(String, String)]? = nil
