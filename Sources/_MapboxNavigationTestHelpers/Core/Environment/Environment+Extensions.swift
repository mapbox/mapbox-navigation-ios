@testable import MapboxNavigationCore

extension MapboxNavigationCore.Environment {
    public static let noop = Environment(
        audioPlayerClient: .noopValue,
        routerClientProvider: .noopValue,
        routeParserClient: .noopValue,
        speechSynthesizerClientProvider: .noopValue
    )

    public static let test = Environment(
        audioPlayerClient: .testValue,
        routerClientProvider: .testValue,
        routeParserClient: .testValue,
        speechSynthesizerClientProvider: .testValue
    )
}
