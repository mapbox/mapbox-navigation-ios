import Foundation
import UIKit
@_spi(MapboxInternal) import MapboxCoreNavigation

/// Manages `UIApplication.shared.isIdleTimerDisabled`. Thread-safe.
final class IdleTimerManager {
    /// While a cancellable isn't cancelled, the idle timer is disabled. A cancellable is cancelled on deallocation.
    final class Cancellable {
        private let onCancel: () -> Void

        fileprivate init(_ onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        deinit {
            onCancel()
        }
    }

    static let shared: IdleTimerManager = .init()

    private let lock: NSLock = .init()
    /// Number of currently non cancelled `IdleTimerManager.Cancellable` instances.
    private var _cancellablesCount: Int = 0 {
        didSet {
            _updateIdleTimer()
        }
    }

    private init() {}

    /**
     Disables idle timer `UIApplication.shared.isIdleTimerDisabled`
     while there is at least one non-cancelled `IdleTimerManager.Cancellable` instance.

     - Returns: An instance of cancellable that you should retain until you want the idle timer to be disabled.
     */
    func disableIdleTimer() -> IdleTimerManager.Cancellable {
        let cancellable = Cancellable {
            self.changeCancellablesCount(delta: -1)
        }
        changeCancellablesCount(delta: 1)
        return cancellable
    }

    private func _updateIdleTimer() {
        let isIdleTimerDisabled = _cancellablesCount > 0

        onMainAsync {
            UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
        }
    }

    private func changeCancellablesCount(delta: Int) {
        lock.lock(); defer {
            lock.unlock()
        }
        _cancellablesCount += delta
    }
}

