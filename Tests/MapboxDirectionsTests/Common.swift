import Foundation
import XCTest

private let accessTokenKey = "access_token"
private let skuKey = "sku"

func checkForDuplicatedParameters(requestQueryItems: ([URLQueryItem]) -> [URLQueryItem]) {
    let customParameterKey = "custom_parameter"
    let customParameterValue = "test_value"

    let queryItems = requestQueryItems([
        URLQueryItem(name: customParameterKey, value: customParameterValue),
    ])

    // Verify no duplicate names exist across all query items
    let allNames = queryItems.map(\.name)
    let uniqueNames = Set(allNames)
    XCTAssertEqual(allNames.count, uniqueNames.count, "All query item names should be unique")
}
