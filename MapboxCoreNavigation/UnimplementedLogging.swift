import Foundation
import os.log

public protocol UnimplementedLogging {
    
    func logUnimplemented(protocolType: Any, level: OSLogType, function: String)
}

public extension UnimplementedLogging {
 
    
    
    func logUnimplemented(protocolType: Any, level: OSLogType, function: String = #function) {
        let protocolDescription = String(describing: protocolType)
        let selfDescription = String(describing: type(of: self))
        let log = OSLog(subsystem: "com.mapbox.navigation", category: "delegation.\(selfDescription)")
           let formatted: StaticString = "Unimplemented Delegate Method in %@: %@.%@"
           os_log(formatted, log: log, type: level, selfDescription, protocolDescription, function)
        
    }
}
