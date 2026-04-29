import MapboxCommon_Private
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private

extension RouteParserClient {
    public static var noopValue: RouteParserClient {
        Self(
            createRoutesData: { _, _ in
                return RoutesDataMock()
            },
            parseDirectionsRoutesForResponse: { _, _, _ in
                return Expected<NSArray, NSString>(value: [])
            },
            parseDirectionsRoutesForResponseWithCallback: { _, _, _, _ in },
            parseDirectionsResponseForResponseDataRef: { _, _, _ in
                return Expected<NSArray, NSString>(value: [])
            },
            parseDirectionsResponseForResponseDataRefWithCallback: { _, _, _, _ in },
            parseMapMatchingResponseForResponseDataRef: { _, _, _ in
                return Expected<NSArray, NSString>(value: [])
            },
            parseMapMatchingResponseForResponseDataRefWithCallback: { _, _, _, _ in }
        )
    }
}

extension RouteParserClient {
    public static var testValue: RouteParserClient {
        Self(
            createRoutesData: { _, _ in
                fatalError("not implemented")
            },
            parseDirectionsRoutesForResponse: { _, _, _ in
                fatalError("not implemented")
            },
            parseDirectionsRoutesForResponseWithCallback: { _, _, _, _ in
                fatalError("not implemented")
            },
            parseDirectionsResponseForResponseDataRef: { _, _, _ in
                fatalError("not implemented")
            },
            parseDirectionsResponseForResponseDataRefWithCallback: { _, _, _, _ in
                fatalError("not implemented")
            },
            parseMapMatchingResponseForResponseDataRef: { _, _, _ in
                fatalError("not implemented")
            },
            parseMapMatchingResponseForResponseDataRefWithCallback: { _, _, _, _ in
                fatalError("not implemented")
            }
        )
    }
}
