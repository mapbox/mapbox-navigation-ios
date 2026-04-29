import MapboxDirections
import XCTest

class AttributeOptionsTests: XCTestCase {
    func testInsertion() {
        var options = AttributeOptions()
        var options2merge = AttributeOptions(descriptions: ["speed"])!
        var optionsWithCustom = AttributeOptions()

        optionsWithCustom.update(customOption: (1 << 7, "Custom7"), comparisonPolicy: .equal)
        options.update(with: .distance)
        options.update(with: optionsWithCustom)
        options2merge.update(customOption: (1 << 8, "Custom_8"), comparisonPolicy: .equal)

        options.update(with: options2merge)

        // Check merged options are collected
        XCTAssertEqual(
            options.rawValue,
            AttributeOptions.speed.rawValue + AttributeOptions.distance.rawValue + 1 << 7 + 1 << 8
        )
        XCTAssertEqual(
            options.description.split(separator: ",").count,
            4
        )
        XCTAssertEqual(
            optionsWithCustom,
            options.update(customOption: (1 << 7, "Custom7"), comparisonPolicy: .equal)
        )

        // insert existing default
        XCTAssertFalse(options.insert(.distance).inserted)
        // insert existing custom
        XCTAssertFalse(options.insert(optionsWithCustom).inserted)
        // insert conflicting custom
        var optionsWithConflict = AttributeOptions()
        optionsWithConflict.update(
            customOption: (optionsWithCustom.rawValue, "Another custom name"),
            comparisonPolicy: .equal
        )
        XCTAssertFalse(options.insert(optionsWithConflict, comparisonPolicy: .rawValueEqual).inserted)
        // insert custom with default raw
        optionsWithConflict.rawValue = AttributeOptions.distance.rawValue
        XCTAssertFalse(options.insert(optionsWithConflict).inserted)
    }

    func testContains() {
        var options = AttributeOptions()
        options.update(with: .expectedTravelTime)
        options.update(customOption: (1 << 9, "Custom"), comparisonPolicy: .equal)

        XCTAssertTrue(options.contains(.init(rawValue: AttributeOptions.expectedTravelTime.rawValue)))
        XCTAssertFalse(options.contains(.congestionLevel))

        var wrongCustomOption = AttributeOptions()
        wrongCustomOption.update(customOption: (1 << 9, "Wrong name"), comparisonPolicy: .equal)
        XCTAssertFalse(options.contains(wrongCustomOption))

        var correctCustomOption = AttributeOptions()
        correctCustomOption.update(customOption: (1 << 9, "Custom"), comparisonPolicy: .equal)
        XCTAssertTrue(options.contains(correctCustomOption))

        XCTAssertTrue(options.contains(.init(rawValue: 1 << 9), comparisonPolicy: .equalOrNull))
    }

    func testRemove() {
        var preservedOption = AttributeOptions()
        preservedOption.update(customOption: (1 << 12, "Should be preserved"), comparisonPolicy: .equal)
        var options = AttributeOptions()
        options.update(with: .congestionLevel)
        options.update(with: .distance)
        options.update(customOption: (1 << 10, "Custom"), comparisonPolicy: .equal)
        options.update(with: preservedOption)

        // Removing default item
        let distance = options.remove(AttributeOptions(descriptions: ["distance"])!)

        XCTAssertEqual(distance?.rawValue, AttributeOptions.distance.rawValue)
        XCTAssertTrue(options.contains(.congestionLevel))
        XCTAssertTrue(options.contains(preservedOption))

        // Removing not existing item by raw value
        XCTAssertNil(options.remove(AttributeOptions(rawValue: 1)))
        XCTAssertTrue(options.contains(.congestionLevel))
        XCTAssertTrue(options.contains(preservedOption))

        // Removing custom option with incorrect name
        var wrongCustomOption = AttributeOptions()
        wrongCustomOption.update(customOption: (1 << 10, "Wrong name"), comparisonPolicy: .equal)

        XCTAssertNil(options.remove(wrongCustomOption))
        XCTAssertTrue(options.contains(.congestionLevel))
        XCTAssertTrue(options.contains(preservedOption))

        // Removing existing custom option
        var correctCustomOption = AttributeOptions()
        correctCustomOption.update(customOption: (1 << 10, "Custom"), comparisonPolicy: .equal)

        XCTAssertEqual(options.remove(correctCustomOption), correctCustomOption)
        XCTAssertTrue(options.contains(.congestionLevel))
        XCTAssertTrue(options.contains(preservedOption))

        // Removing custom option with default raw value
        var customOptionWithDefaultRaw = AttributeOptions()
        customOptionWithDefaultRaw.update(
            customOption: (AttributeOptions.distance.rawValue, "Not a distance"),
            comparisonPolicy: .equal
        )
        XCTAssertNil(options.remove(customOptionWithDefaultRaw))

        // Removing custom option by raw value only
        options.update(with: correctCustomOption)
        XCTAssertEqual(options.remove(.init(rawValue: 1 << 10), comparisonPolicy: .equalOrNull), correctCustomOption)
    }

    func testCustomAttributes() {
        let customOption1 = (1, "atmospheric pressure")
        let customOption2 = (1 << 10, "space radiation")
        var attributes = AttributeOptions()
        attributes.insert(.congestionLevel)
        attributes.insert(.speed)
        attributes.update(customOption: customOption1, comparisonPolicy: .equal)
        attributes.update(customOption: customOption2, comparisonPolicy: .equal)

        let descriptions = attributes.description.split(separator: ",")
        XCTAssertTrue(descriptions.contains { $0 == AttributeOptions.congestionLevel.description })
        XCTAssertTrue(descriptions.contains { $0 == AttributeOptions.speed.description })
        XCTAssertTrue(descriptions.contains { $0 == customOption1.1 })
        XCTAssertTrue(descriptions.contains { $0 == customOption2.1 })
    }
}
