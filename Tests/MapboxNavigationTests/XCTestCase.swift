import Foundation
import XCTest

extension XCTestCase {
    enum NavigationTests {
        static var timeout: DispatchTime {
            return DispatchTime.now() + DispatchTimeInterval.seconds(10)
        }

        static let pollingInterval: TimeInterval = 0.05
    }

    func runUntil(_ condition: () -> Bool, testCase: String = #function) {
        runUntil(condition: condition, testCase: testCase, pollingInterval: NavigationTests.pollingInterval, until: NavigationTests.timeout)
    }

    func runUntil(condition: () -> Bool, testCase: String, pollingInterval: TimeInterval, until timeout: DispatchTime) {
        guard (timeout >= DispatchTime.now()) else {
            XCTFail("Timeout occurred in \(testCase)")
            return
        }

        if condition() == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollingInterval))
            runUntil(condition: condition, testCase: testCase, pollingInterval: pollingInterval, until: timeout)
        }
    }
}
