import CarPlay
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

/// Left-hand maneuver symbols are produced by drawing the right-hand glyph and mirroring it. The mirroring has to
/// end up in the pixel data, because CarPlay on some iOS versions may render `CPImageSet` contents without honoring
/// `UIImage.imageOrientation`, causing arrows to point the wrong way.
///
/// These tests read raw `CGImage` pixels rather than wrapping images in `UIImageView`, which applies
/// `imageOrientation` and would hide the defect.
final class ManeuverImageOrientationTests: TestCase {
    private let imageSize = CGSize(width: 30, height: 30)

    // MARK: Mirrored maneuvers

    func testTurnLeftMirrorsTurnRight() throws {
        try assertMirrorsReference(
            instruction(.turn, .left),
            reference: instruction(.turn, .right)
        )
    }

    func testSlightLeftMirrorsSlightRight() throws {
        try assertMirrorsReference(
            instruction(.turn, .slightLeft),
            reference: instruction(.turn, .slightRight)
        )
    }

    func testSharpLeftMirrorsSharpRight() throws {
        try assertMirrorsReference(
            instruction(.turn, .sharpLeft),
            reference: instruction(.turn, .sharpRight)
        )
    }

    func testMergeLeftMirrorsMergeRight() throws {
        try assertMirrorsReference(
            instruction(.merge, .left),
            reference: instruction(.merge, .right)
        )
    }

    func testOffRampLeftMirrorsOffRampRight() throws {
        try assertMirrorsReference(
            instruction(.takeOffRamp, .left),
            reference: instruction(.takeOffRamp, .right)
        )
    }

    func testForkLeftMirrorsForkRight() throws {
        try assertMirrorsReference(
            instruction(.reachFork, .left),
            reference: instruction(.reachFork, .right)
        )
    }

    func testArriveLeftMirrorsArriveRight() throws {
        try assertMirrorsReference(
            instruction(.arrive, .left),
            reference: instruction(.arrive, .right)
        )
    }

    func testUTurnMirrorsOnRightHandTraffic() throws {
        try assertMirrorsReference(
            instruction(.turn, .uTurn),
            drivingSide: .right,
            reference: instruction(.turn, .uTurn),
            referenceDrivingSide: .left
        )
    }

    func testRoundaboutMirrorsOnLeftHandTraffic() throws {
        try assertMirrorsReference(
            instruction(.takeRoundabout, .left, degrees: 270),
            drivingSide: .left,
            reference: instruction(.takeRoundabout, .left, degrees: 270),
            referenceDrivingSide: .right
        )
    }

    func testRotaryMirrorsOnLeftHandTraffic() throws {
        try assertMirrorsReference(
            instruction(.takeRotary, .left, degrees: 270),
            drivingSide: .left,
            reference: instruction(.takeRotary, .left, degrees: 270),
            referenceDrivingSide: .right
        )
    }

    // MARK: Non-mirrored maneuvers

    func testNonMirroredManeuversUseUpOrientation() throws {
        let instructions = [
            instruction(.turn, .right),
            instruction(.turn, .slightRight),
            instruction(.turn, .sharpRight),
            instruction(.turn, .straightAhead),
            instruction(.merge, .right),
            instruction(.arrive, .right),
            instruction(.arrive, nil),
        ]

        for instruction in instructions {
            let image = try XCTUnwrap(maneuverImage(for: instruction, drivingSide: .right))
            XCTAssertEqual(
                image.imageOrientation,
                .up,
                "\(instruction.maneuverType?.rawValue ?? "turn")/" +
                    "\(instruction.maneuverDirection?.rawValue ?? "none") should not be mirrored."
            )
        }
    }

    // MARK: CarPlay image set

    func testMirroredManeuverBakesFlipIntoDrawWithoutViewTransform() throws {
        let view = ManeuverView(frame: CGRect(origin: .zero, size: imageSize))
        view.backgroundColor = .clear
        view.visualInstruction = instruction(.turn, .left)
        view.drivingSide = .right

        let image = try XCTUnwrap(view.imageRepresentation)
        XCTAssertEqual(
            view.transform,
            .identity,
            "Mirroring belongs in the drawing context so layer snapshots and CarPlay images match without a second blit."
        )
        XCTAssertEqual(image.imageOrientation, .up)

        let rightView = ManeuverView(frame: CGRect(origin: .zero, size: imageSize))
        rightView.backgroundColor = .clear
        rightView.visualInstruction = instruction(.turn, .right)
        let rightImage = try XCTUnwrap(rightView.imageRepresentation)

        let leftPixels = try pixels(of: image)
        let rightPixels = try pixels(of: rightImage)
        assertPixelsMatch(leftPixels.bytes, rightPixels.horizontallyMirrored())
    }

    func testCarPlayImageSetBakesMirrorIntoBothVariants() throws {
        let leftInstruction = instruction(.turn, .left)
        let rightInstruction = instruction(.turn, .right)

        let leftImageSet = try XCTUnwrap(leftInstruction.maneuverImageSet(
            side: .right,
            visualInstruction: leftInstruction
        ))
        let rightImageSet = try XCTUnwrap(rightInstruction.maneuverImageSet(
            side: .right,
            visualInstruction: rightInstruction
        ))

        for (left, right) in [
            (leftImageSet.lightContentImage, rightImageSet.lightContentImage),
            (leftImageSet.darkContentImage, rightImageSet.darkContentImage),
        ] {
            XCTAssertEqual(left.imageOrientation, .up)
            XCTAssertEqual(right.imageOrientation, .up)

            let leftPixels = try pixels(of: left)
            let rightPixels = try pixels(of: right)
            assertPixelsMatch(leftPixels.bytes, rightPixels.horizontallyMirrored())
        }
    }

    // MARK: Helpers

    private func assertMirrorsReference(
        _ instruction: VisualInstruction,
        drivingSide: DrivingSide = .right,
        reference: VisualInstruction,
        referenceDrivingSide: DrivingSide = .right,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let mirroredImage = try XCTUnwrap(
            maneuverImage(for: instruction, drivingSide: drivingSide),
            file: file,
            line: line
        )
        let referenceImage = try XCTUnwrap(
            maneuverImage(for: reference, drivingSide: referenceDrivingSide),
            file: file,
            line: line
        )

        XCTAssertEqual(
            mirroredImage.imageOrientation,
            .up,
            "The mirror must live in the pixel data, not in orientation metadata.",
            file: file,
            line: line
        )
        XCTAssertEqual(referenceImage.imageOrientation, .up, file: file, line: line)

        let mirroredPixels = try pixels(of: mirroredImage, file: file, line: line)
        let referencePixels = try pixels(of: referenceImage, file: file, line: line)

        XCTAssertNotEqual(
            referencePixels.bytes,
            referencePixels.horizontallyMirrored(),
            "The reference glyph is symmetric, so this comparison cannot detect a missing mirror.",
            file: file,
            line: line
        )
        assertPixelsMatch(
            mirroredPixels.bytes,
            referencePixels.horizontallyMirrored(),
            file: file,
            line: line
        )
    }

    private func assertPixelsMatch(
        _ lhs: [UInt8],
        _ rhs: [UInt8],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard lhs.count == rhs.count else {
            return XCTFail("Images differ in size: \(lhs.count) vs \(rhs.count) bytes.", file: file, line: line)
        }

        let differences = zip(lhs, rhs).map { abs(Int($0) - Int($1)) }
        let mean = Double(differences.reduce(0, +)) / Double(differences.count)
        XCTAssertLessThanOrEqual(
            mean,
            1,
            "Mean channel difference \(mean) (max \(differences.max() ?? 0)) is too large to be a mirrored render.",
            file: file,
            line: line
        )
    }

    private func maneuverImage(for instruction: VisualInstruction, drivingSide: DrivingSide) -> UIImage? {
        instruction.maneuverViewImage(
            drivingSide: drivingSide,
            visualInstruction: instruction,
            color: .black,
            size: imageSize
        )
    }

    private func instruction(
        _ maneuverType: ManeuverType?,
        _ maneuverDirection: ManeuverDirection?,
        degrees: CLLocationDegrees = 180
    ) -> VisualInstruction {
        VisualInstruction(
            text: "",
            maneuverType: maneuverType,
            maneuverDirection: maneuverDirection,
            components: [.delimiter(text: .init(text: "", abbreviation: nil, abbreviationPriority: nil))],
            degrees: degrees
        )
    }

    /// Reads the pixels backing the image while ignoring `imageOrientation`, matching the affected CarPlay behavior.
    private func pixels(
        of image: UIImage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Bitmap {
        let cgImage = try XCTUnwrap(image.cgImage, file: file, line: line)
        let width = cgImage.width
        let height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        let didDraw = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        XCTAssertTrue(didDraw, "Could not read pixels of the maneuver image.", file: file, line: line)
        XCTAssertTrue(bytes.contains { $0 != 0 }, "The maneuver image is blank.", file: file, line: line)

        return Bitmap(bytes: bytes, width: width, height: height)
    }

    private struct Bitmap {
        let bytes: [UInt8]
        let width: Int
        let height: Int

        func horizontallyMirrored() -> [UInt8] {
            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            var mirrored = bytes

            for y in 0..<height {
                for x in 0..<width {
                    let source = y * bytesPerRow + x * bytesPerPixel
                    let destination = y * bytesPerRow + (width - 1 - x) * bytesPerPixel
                    for component in 0..<bytesPerPixel {
                        mirrored[destination + component] = bytes[source + component]
                    }
                }
            }

            return mirrored
        }
    }
}
