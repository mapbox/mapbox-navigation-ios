@testable import MapboxDirections
import Turf
import XCTest

class SpokenInstructionTests: XCTestCase {
    func testCoding() {
        let instructionJSON: [String: Any] = [
            "distanceAlongGeometry": 20.8,
            "announcement": "Head east on Hageman Street, then turn right onto Reading Road",
            "ssmlAnnouncement": "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Head east on Hageman Street, then turn right onto <phoneme ph=\"ˈɹɛdɪŋ ˈɹoʊd\">Reading Road</phoneme></prosody></amazon:effect></speak>",
        ]
        let instructionData = try! JSONSerialization.data(withJSONObject: instructionJSON, options: [])
        var instruction: SpokenInstruction?
        XCTAssertNoThrow(instruction = try JSONDecoder().decode(SpokenInstruction.self, from: instructionData))
        XCTAssertNotNil(instruction)
        if let instruction {
            XCTAssertEqual(instruction.distanceAlongStep, instructionJSON["distanceAlongGeometry"] as! LocationDistance)
            XCTAssertEqual(instruction.text, instructionJSON["announcement"] as! String)
            XCTAssertEqual(instruction.ssmlText, instructionJSON["ssmlAnnouncement"] as! String)
        }

        instruction = SpokenInstruction(
            distanceAlongStep: instructionJSON["distanceAlongGeometry"] as! LocationDistance,
            text: instructionJSON["announcement"] as! String,
            ssmlText: instructionJSON["ssmlAnnouncement"] as! String
        )
        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(instruction))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedInstructionJSON: [String: Any?]?
            XCTAssertNoThrow(encodedInstructionJSON = try JSONSerialization.jsonObject(
                with: encodedData,
                options: []
            ) as? [String: Any?])
            XCTAssertNotNil(encodedInstructionJSON)

            XCTAssert(JSONSerialization.objectsAreEqual(instructionJSON, encodedInstructionJSON, approximate: true))
        }
    }

    func testEquality() {
        let left = SpokenInstruction(distanceAlongStep: 0, text: "", ssmlText: "")
        XCTAssertEqual(left, left)

        var right = SpokenInstruction(distanceAlongStep: 0, text: "", ssmlText: "")
        XCTAssertEqual(left, right)

        right = SpokenInstruction(distanceAlongStep: 0.001, text: "", ssmlText: "")
        XCTAssertNotEqual(left, right)

        right = SpokenInstruction(distanceAlongStep: 0, text: "Get lost", ssmlText: "")
        XCTAssertNotEqual(left, right)

        right = SpokenInstruction(
            distanceAlongStep: 0,
            text: "",
            ssmlText: "<speak>Get <say-as interpret-as=\"expletive\"></say-as> lost</speak>"
        )
        XCTAssertNotEqual(left, right)
    }

    func testDecodingSucceeds() throws {
        let data = try makeSpokenInstructionData()
        XCTAssertNoThrow(try JSONDecoder().decode(SpokenInstruction.self, from: data))
    }

    func testDecodingFailsWhenMissingDistanceAlongGeometry() throws {
        let data = try makeSpokenInstructionData(overriding: ["distanceAlongGeometry": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(SpokenInstruction.self, from: data))
    }

    func testDecodingFailsWhenMissingAnnouncement() throws {
        let data = try makeSpokenInstructionData(overriding: ["announcement": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(SpokenInstruction.self, from: data))
    }

    func testDecodingFailsWhenMissingSSMLAnnouncement() throws {
        let data = try makeSpokenInstructionData(overriding: ["ssmlAnnouncement": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(SpokenInstruction.self, from: data))
    }

    func testSSMLWithAmpersandEntitiesDecodesUnchanged() throws {
        let ssml = "<speak>Turn left toward <say-as>Chili&apos;s Bar &amp; Grill</say-as></speak>"
        let data = try makeSpokenInstructionData(overriding: ["ssmlAnnouncement": ssml])
        let instruction = try JSONDecoder().decode(SpokenInstruction.self, from: data)
        XCTAssertEqual(instruction.ssmlText, ssml)
    }

    // MARK: - Helpers

    private func makeSpokenInstructionData(overriding overrides: [String: Any?] = [:]) throws -> Data {
        var dict: [String: Any] = [
            "distanceAlongGeometry": 100.0,
            "announcement": "Test instruction",
            "ssmlAnnouncement": "<speak>Test instruction</speak>",
        ]
        for (key, value) in overrides {
            if let value {
                dict[key] = value
            } else {
                dict.removeValue(forKey: key)
            }
        }
        return try JSONSerialization.data(withJSONObject: dict)
    }
}
