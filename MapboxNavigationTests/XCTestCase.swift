import Foundation
import XCTest

extension XCTestCase {
    
    func runUntil(condition: @autoclosure () -> Bool, pollingInterval: TimeInterval, until timeout: DispatchTime) {
        guard (timeout >= DispatchTime.now()) else {
            XCTFail("Timeout occurred on \(#function)")
            return
        }
        
        if condition() == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollingInterval))
            runUntil(condition: condition, pollingInterval: pollingInterval, until: timeout)
        }
    }
    
    enum NavigationTests {
        static let imageDownloadTimeout = 5.0
        static let timeout: TimeInterval = 2.0
        static let deadline: DispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(Int(timeout))
    }
}
