import Foundation
import os.log

public protocol UnimplementedLogging {
        
    var delegateIdentifier: String { get }
    
    func logUnimplemented(level: OSLogType, function: String)
}

public extension UnimplementedLogging {
 
    func logUnimplemented(level: OSLogType, function: String = #function) {
        let log = OSLog(subsystem: "com.mapbox.navigation", category: "delegation.\(delegateIdentifier)")
           let formatted: StaticString = "Unimplemented Delegate Method in %@: %@"
        let selfDescription = String(describing: type(of: self))
           os_log(formatted, log: log, type: level, selfDescription, function)
        
    }
}
