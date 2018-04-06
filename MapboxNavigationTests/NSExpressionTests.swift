import XCTest
@testable import MapboxNavigation

class NSExpressionTests: XCTestCase {
    func testLocalization() {
        let jsonExpression: [Any] = [
            "step",
            ["zoom"],
            [
                "case",
                [
                    "<",
                    [
                        "number",
                        ["get", "area"]
                    ],
                    80000
                ],
                ["get", "abbr"],
                ["get", "name_en"]
            ],
            5, ["get", "name_en"]
        ]
        let localizedJSONExpression: [Any] = [
            "step",
            ["zoom"],
            [
                "case",
                [
                    "<",
                    [
                        "number",
                        ["get", "area"]
                    ],
                    80000
                ],
                ["get", "abbr"],
                ["get", "name"]
            ],
            5, ["get", "name"]
        ]
        let expression = NSExpression.mgl_expression(withJSONObject: jsonExpression)
        let localizedExpression = expression.localized(into: nil, replacingTokens: false)
        XCTAssertEqual(localizedExpression.mgl_jsonExpressionObject as! NSArray, localizedJSONExpression as NSArray)
    }
    
    func testTokenLocalization() {
        let expression = NSExpression.mgl_expression(withJSONObject: "{name_en}")
        
        var localizedExpression = expression.localized(into: nil, replacingTokens: false)
        XCTAssertEqual(localizedExpression.mgl_jsonExpressionObject as! String, "{name_en}")
        
        localizedExpression = expression.localized(into: nil, replacingTokens: false)
        XCTAssertEqual(localizedExpression.mgl_jsonExpressionObject as! String, "{name_en}")
        
        localizedExpression = expression.localized(into: nil, replacingTokens: true)
        XCTAssertEqual(localizedExpression.mgl_jsonExpressionObject as! String, "{name}")
        
        localizedExpression = expression.localized(into: Locale(identifier: "es"), replacingTokens: true)
        XCTAssertEqual(localizedExpression.mgl_jsonExpressionObject as! String, "{name_es}")
        
        localizedExpression = expression.localized(into: Locale(identifier: "zh-Hans"), replacingTokens: true)
        XCTAssertEqual(localizedExpression.mgl_jsonExpressionObject as! String, "{name_zh-Hans}")
    }
    
    func testFunctionTokenLocalization() {
        let expression = NSExpression(format: "mgl_step:from:stops:($zoomLevel, '', %@)", [13: "{name_en}"])
        let expected = NSExpression(format: "mgl_step:from:stops:($zoomLevel, '', %@)", [13: "{name_en}"])
        let actual = expression.localized(into: Locale(identifier: "ru-RU"), replacingTokens: true)
        XCTAssertEqual(actual, expected)
    }
}
