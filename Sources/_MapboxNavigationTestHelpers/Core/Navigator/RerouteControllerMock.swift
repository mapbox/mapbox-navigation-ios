import Foundation
@testable import MapboxNavigationCore
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

extension RerouteController {
    @MainActor
    public static func mock(
        navigator: NavigationNativeNavigator,
        credentials: ApiConfiguration = .mock(),
        configHandle: ConfigHandle = .mock(),
        rerouteConfig: RerouteConfig = .init(),
        initialManeuverAvoidanceRadius: TimeInterval = 60.0
    ) -> Self {
        .init(
            configuration: Configuration(
                credentials: credentials,
                navigator: navigator,
                configHandle: configHandle,
                rerouteConfig: rerouteConfig,
                initialManeuverAvoidanceRadius: initialManeuverAvoidanceRadius
            )
        )
    }
}
