import Foundation
import MapboxNavigationNative

class NavigatorFallbackVersionsObserver: FallbackVersionsObserver {
    private(set) var tileVersionState: TileVersionState = .nominal

    typealias RestartCallback = (String?) -> Void
    let restartCallback: RestartCallback

    init(restartCallback: @escaping RestartCallback) {
        self.restartCallback = restartCallback
    }

    enum TileVersionState {
        /// No tiles version switch is required. Navigator has enough tiles for map matching.
        case nominal
        /// Navigator does not have tiles on current version for map matching, but TileStore contains regions with
        /// required tiles of a different version
        case shouldFallback([String])
        /// Navigator is in a fallback mode but newer tiles version were successefully downloaded and ready to use.
        case shouldReturnToLatest
    }

    func onFallbackVersionsFound(forVersions versions: [String]) {
        switch tileVersionState {
        case .nominal, .shouldReturnToLatest:
            tileVersionState = .shouldFallback(versions)
            guard let fallbackVersion = versions.last else { return }

            restartCallback(fallbackVersion)

            let userInfo: [NativeNavigator.NotificationUserInfoKey: Any] = [
                .tilesVersionKey: fallbackVersion,
            ]

            NotificationCenter.default.post(
                name: .navigationDidSwitchToFallbackVersion,
                object: nil,
                userInfo: userInfo
            )
        case .shouldFallback:
            break // do nothing
        }
    }

    func onCanReturnToLatest(forVersion version: String) {
        switch tileVersionState {
        case .nominal, .shouldFallback:
            tileVersionState = .shouldReturnToLatest

            restartCallback(nil)

            let userInfo: [NativeNavigator.NotificationUserInfoKey: Any] = [
                .tilesVersionKey: version,
            ]

            NotificationCenter.default.post(
                name: .navigationDidSwitchToTargetVersion,
                object: nil,
                userInfo: userInfo
            )
        case .shouldReturnToLatest:
            break // do nothing
        }
    }
}
