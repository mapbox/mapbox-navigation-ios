@testable import MapboxNavigation
@testable import MapboxCoreNavigation
import MapboxDirections
import XCTest
import Foundation
import TestHelper


@available(iOS 12.0, *)
fileprivate class CarPlayNavigationDelegateSpy: NSObject, CarPlayNavigationDelegate {
    var didArriveExpectation: XCTestExpectation!
    
    init(_ didArriveExpectation: XCTestExpectation) {
        self.didArriveExpectation = didArriveExpectation
    }
    
}
