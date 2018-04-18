import Foundation
import XCTest

extension XCTestCase {
    enum NavigationTests {
        static let timeout: DispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(8)
    }
}
