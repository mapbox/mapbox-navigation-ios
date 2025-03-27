@testable import MapboxNavigationCore

extension MapboxNavigationCore.Environment {
    public static let noop = Environment(
        audioPlayerClient: .noopValue,
        routerProviderClient: .noopValue,
        routeParserClient: .noopValue
    )

    public static let test = Environment(
        audioPlayerClient: .testValue,
        routerProviderClient: .testValue,
        routeParserClient: .testValue
    )
}
