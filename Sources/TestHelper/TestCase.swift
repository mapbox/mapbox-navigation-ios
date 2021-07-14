import Foundation
import XCTest
@testable import MapboxDirections

/// Base Mapbox XCTestCase class with common setup logic
open class TestCase: XCTestCase {
    /// Inidicates whether one time initialization completed in ``initializeIfNeeded`` method.
    private static var isInitializationCompleted: Bool = false

    open override class func setUp() {
        super.setUp()
        initializeIfNeeded()
    }

    /// Prepares tests for execution. Should be called once before any test runs.
    private static func initializeIfNeeded() {
        guard !isInitializationCompleted else { return }
        isInitializationCompleted = true

        DirectionsCredentials.injectSharedToken(.mockedAccessToken)
        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationWhenInUseUsageDescription")
        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
    }
}
