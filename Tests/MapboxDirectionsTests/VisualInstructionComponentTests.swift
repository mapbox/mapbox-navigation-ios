@testable import MapboxDirections
import XCTest

class VisualInstructionComponentTests: XCTestCase {
    func testTextComponent() {
        let componentJSON = [
            "type": "text",
            "text": "Take a hike",
            "imageBaseURL": "",
        ]
        let componentData = try! JSONSerialization.data(withJSONObject: componentJSON, options: [])
        var component: VisualInstruction.Component?
        XCTAssertNoThrow(component = try JSONDecoder().decode(VisualInstruction.Component.self, from: componentData))
        XCTAssertNotNil(component)
        if let component {
            switch component {
            case .text(let text):
                XCTAssertEqual(text.text, "Take a hike")
            default:
                XCTFail("Text component should not be decoded as any other kind of component.")
            }
        }
    }

    @MainActor
    func testImageComponent() {
        let componentJSON: [String: Any] = [
            "text": "I 95",
            "type": "icon",
            "imageBaseURL": "https://s3.amazonaws.com/mapbox/shields/v3/i-95",
            "mapbox_shield": [
                "base_url": "https://api.mapbox.com/styles/v1/",
                "name": "us-interstate",
                "text_color": "white",
                "display_ref": "95",
            ],
        ]
        let componentData = try! JSONSerialization.data(withJSONObject: componentJSON, options: [])
        var component: VisualInstruction.Component?
        XCTAssertNoThrow(component = try JSONDecoder().decode(VisualInstruction.Component.self, from: componentData))
        XCTAssertNotNil(component)
        if let component {
            switch component {
            case .image(let image, let alternativeText):
                XCTAssertEqual(image.imageBaseURL?.absoluteString, "https://s3.amazonaws.com/mapbox/shields/v3/i-95")
                XCTAssertEqual(
                    image.imageURL(scale: 1, format: .svg)?.absoluteString,
                    "https://s3.amazonaws.com/mapbox/shields/v3/i-95@1x.svg"
                )
                XCTAssertEqual(
                    image.imageURL(scale: 3, format: .svg)?.absoluteString,
                    "https://s3.amazonaws.com/mapbox/shields/v3/i-95@3x.svg"
                )
                XCTAssertEqual(
                    image.imageURL(scale: 3, format: .png)?.absoluteString,
                    "https://s3.amazonaws.com/mapbox/shields/v3/i-95@3x.png"
                )
                XCTAssertEqual(alternativeText.text, "I 95")
                XCTAssertNil(alternativeText.abbreviation)
                XCTAssertNil(alternativeText.abbreviationPriority)
                XCTAssertEqual(image.shield?.baseURL, URL(string: "https://api.mapbox.com/styles/v1/")!)
                XCTAssertEqual(image.shield?.name, "us-interstate")
                XCTAssertEqual(image.shield?.textColor, "white")
                XCTAssertEqual(image.shield?.text, "95")
            default:
                XCTFail("Image component should not be decoded as any other kind of component.")
            }
        }
        let shield = VisualInstruction.Component.ShieldRepresentation(
            baseURL: URL(string: "https://api.mapbox.com/styles/v1/")!,
            name: "us-interstate",
            textColor: "white",
            text: "95"
        )
        component = .image(
            image: .init(imageBaseURL: URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/i-95")!, shield: shield),
            alternativeText: .init(text: "I 95", abbreviation: nil, abbreviationPriority: nil)
        )
        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(component))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedComponentJSON: [String: Any?]?
            XCTAssertNoThrow(encodedComponentJSON = try JSONSerialization.jsonObject(
                with: encodedData,
                options: []
            ) as? [String: Any?])
            XCTAssertNotNil(encodedComponentJSON)

            XCTAssert(JSONSerialization.objectsAreEqual(componentJSON, encodedComponentJSON, approximate: false))
        }
    }

    func testShield() {
        let shieldJSON = [
            "base_url": "https://api.mapbox.com/styles/v1/",
            "name": "us-interstate",
            "text_color": "white",
            "display_ref": "95",
        ]

        let shieldData = try! JSONSerialization.data(withJSONObject: shieldJSON, options: [])
        var shield: VisualInstruction.Component.ShieldRepresentation?
        XCTAssertNoThrow(shield = try JSONDecoder().decode(
            VisualInstruction.Component.ShieldRepresentation.self,
            from: shieldData
        ))
        XCTAssertNotNil(shield)
        let url = URL(string: "https://api.mapbox.com/styles/v1/")
        if let shield {
            XCTAssertEqual(shield.baseURL, url)
            XCTAssertEqual(shield.name, "us-interstate")
            XCTAssertEqual(shield.textColor, "white")
            XCTAssertEqual(shield.text, "95")
        }
        shield = .init(baseURL: url!, name: "us-interstate", textColor: "white", text: "95")

        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(shield))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedShieldJSON: [String: Any]?
            XCTAssertNoThrow(
                encodedShieldJSON = try JSONSerialization
                    .jsonObject(with: encodedData, options: []) as? [String: Any]
            )
            XCTAssertNotNil(encodedShieldJSON)

            XCTAssert(JSONSerialization.objectsAreEqual(shieldJSON, encodedShieldJSON, approximate: false))
        }
    }

    func testShieldImageComponent() {
        let componentJSON: [String: Any] = [
            "text": "I 95",
            "type": "icon",
            "mapbox_shield": [
                "base_url": "https://api.mapbox.com/styles/v1/",
                "name": "us-interstate",
                "text_color": "white",
                "display_ref": "95",
            ],
        ]
        let componentData = try! JSONSerialization.data(withJSONObject: componentJSON, options: [])
        var component: VisualInstruction.Component?
        XCTAssertNoThrow(component = try JSONDecoder().decode(VisualInstruction.Component.self, from: componentData))
        XCTAssertNotNil(component)
        if let component {
            switch component {
            case .image(let image, let alternativeText):
                XCTAssertNil(image.imageBaseURL?.absoluteString)
                XCTAssertEqual(alternativeText.text, "I 95")
                XCTAssertNil(alternativeText.abbreviation)
                XCTAssertNil(alternativeText.abbreviationPriority)
                XCTAssertEqual(image.shield?.baseURL, URL(string: "https://api.mapbox.com/styles/v1/")!)
                XCTAssertEqual(image.shield?.name, "us-interstate")
                XCTAssertEqual(image.shield?.textColor, "white")
                XCTAssertEqual(image.shield?.text, "95")
            default:
                XCTFail("Image component should not be decoded as any other kind of component.")
            }
        }

        let shield = VisualInstruction.Component.ShieldRepresentation(
            baseURL: URL(string: "https://api.mapbox.com/styles/v1/")!,
            name: "us-interstate",
            textColor: "white",
            text: "95"
        )
        component = .image(
            image: .init(imageBaseURL: nil, shield: shield),
            alternativeText: .init(text: "I 95", abbreviation: nil, abbreviationPriority: nil)
        )
        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(component))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedComponentJSON: [String: Any?]?
            XCTAssertNoThrow(encodedComponentJSON = try JSONSerialization.jsonObject(
                with: encodedData,
                options: []
            ) as? [String: Any?])
            XCTAssertNotNil(encodedComponentJSON)

            XCTAssert(JSONSerialization.objectsAreEqual(componentJSON, encodedComponentJSON, approximate: false))
        }
    }

    func testLaneComponent() {
        let componentJSON: [String: Any?] = [
            "text": "",
            "type": "lane",
            "active": true,
            "directions": ["right", "straight"],
            "active_direction": "right",
        ]
        let componentData = try! JSONSerialization.data(withJSONObject: componentJSON, options: [])
        var component: VisualInstruction.Component?
        XCTAssertNoThrow(component = try JSONDecoder().decode(VisualInstruction.Component.self, from: componentData))
        XCTAssertNotNil(component)
        if let component {
            if case .lane(let indications, let isUsable, let preferredDirection) = component {
                XCTAssertEqual(indications, [.straightAhead, .right])
                XCTAssertTrue(isUsable)
                XCTAssertEqual(preferredDirection, .right)
            } else {
                XCTFail("Lane component should not be decoded as any other kind of component.")
            }
        }

        component = .lane(indications: [.straightAhead, .right], isUsable: true, preferredDirection: .right)
        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(component))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedComponentJSON: [String: Any?]?
            XCTAssertNoThrow(encodedComponentJSON = try JSONSerialization.jsonObject(
                with: encodedData,
                options: []
            ) as? [String: Any?])
            XCTAssertNotNil(encodedComponentJSON)

            XCTAssert(JSONSerialization.objectsAreEqual(componentJSON, encodedComponentJSON, approximate: false))
        }
    }

    func testUnrecognizedComponent() {
        let componentJSON = [
            "type": "emoji",
            "text": "👈",
        ]
        let componentData = try! JSONSerialization.data(withJSONObject: componentJSON, options: [])
        var component: VisualInstruction.Component?
        XCTAssertNoThrow(component = try JSONDecoder().decode(VisualInstruction.Component.self, from: componentData))
        XCTAssertNotNil(component)
        if let component {
            switch component {
            case .text(let text):
                XCTAssertEqual(text.text, "👈")
            default:
                XCTFail("Component of unrecognized type should be decoded as text component.")
            }
        }
    }
}
