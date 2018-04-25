import Foundation
import XCTest

extension XCTestCase {
    enum NavigationTests {
        static var timeout: DispatchTime {
            return DispatchTime.now() + DispatchTimeInterval.seconds(10)
        }
    }
}
