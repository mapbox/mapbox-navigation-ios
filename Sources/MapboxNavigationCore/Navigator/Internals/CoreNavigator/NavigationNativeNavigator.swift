import Combine
import Foundation
import MapboxCommon
@preconcurrency import MapboxNavigationNative
@preconcurrency import MapboxNavigationNative_Private

final class NavigationNativeNavigator: @unchecked Sendable {
    typealias Completion = @Sendable () -> Void
    @MainActor
    let native: MapboxNavigationNative.Navigator
    var locale: Locale {
        didSet {
            Task { @MainActor in
                updateLocale()
            }
        }
    }

    private var subscriptions: Set<AnyCancellable> = []

    private func withNavigator(_ callback: @escaping @Sendable (MapboxNavigationNative.Navigator) -> Void) {
        Task { @MainActor in
            callback(native)
        }
    }

    @MainActor
    init(
        navigator: MapboxNavigationNative.Navigator,
        locale: Locale
    ) {
        self.native = navigator
        self.locale = locale

        NotificationCenter.default
            .publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateLocale()
            }
            .store(in: &subscriptions)
    }

    @MainActor
    private func updateLocale() {
        native.config().mutableSettings().setUserLanguagesForLanguages(locale.preferredBCP47Codes)
    }

    func removeRouteAlternativesObserver(
        _ observer: RouteAlternativesObserver,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.getRouteAlternativesController().removeObserver(for: observer)
            completion?()
        }
    }

    func startNavigationSession(completion: Completion? = nil) {
        withNavigator {
            $0.startNavigationSession()
            completion?()
        }
    }

    func stopNavigationSession(completion: Completion? = nil) {
        withNavigator {
            $0.stopNavigationSession()
            completion?()
        }
    }

    func setElectronicHorizonOptionsFor(
        _ options: MapboxNavigationNative.ElectronicHorizonOptions?,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.setElectronicHorizonOptionsFor(options)
            completion?()
        }
    }

    func setFallbackVersionsObserverFor(
        _ observer: FallbackVersionsObserver?,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.setFallbackVersionsObserverFor(observer)
            completion?()
        }
    }

    func removeObserver(
        for observer: NavigatorObserver,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.removeObserver(for: observer)
            completion?()
        }
    }

    func removeRouteRefreshObserver(
        for observer: RouteRefreshObserver,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.removeRouteRefreshObserver(for: observer)
            completion?()
        }
    }

    func setElectronicHorizonObserverFor(
        _ observer: ElectronicHorizonObserver?,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.setElectronicHorizonObserverFor(observer)
            completion?()
        }
    }

    func setRerouteControllerForController(
        _ controller: RerouteControllerInterface,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.setRerouteControllerForController(controller)
            completion?()
        }
    }

    func removeRerouteObserver(
        for observer: RerouteObserver,
        completion: Completion? = nil
    ) {
        withNavigator {
            $0.removeRerouteObserver(for: observer)
            completion?()
        }
    }
}

extension MapboxNavigationNative.ElectronicHorizonOptions: @unchecked Sendable {}
