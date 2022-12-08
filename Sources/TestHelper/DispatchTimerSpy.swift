@testable import MapboxCoreNavigation

final class DispatchTimerSpy: DispatchTimer {
    var armCalled = false
    var disarmCalled = false
    var resetCalled = false

    override func arm() {
        armCalled = true
    }

    override func disarm() {
        disarmCalled = true
    }

    override func reset() {
        resetCalled = true
    }

    func resetTestValues() {
        armCalled = false
        disarmCalled = false
        resetCalled = false
    }
}
