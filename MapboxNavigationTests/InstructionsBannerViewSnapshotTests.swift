import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class InstructionsBannerViewSnapshotTests: FBSnapshotTestCase {
    let imageRepository: ImageRepository = ImageRepository.shared

    let asyncTimeout: TimeInterval = 2.0

    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = [.OS, .device]

        let i280Instruction = VisualInstruction.Component.image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I-280", abbreviation: nil, abbreviationPriority: 0))
        let us101Instruction = VisualInstruction.Component.image(image: .init(imageBaseURL: ShieldImage.us101.baseURL), alternativeText: .init(text: "US 101", abbreviation: nil, abbreviationPriority: 0))

        imageRepository.storeImage(ShieldImage.i280.image, forKey: i280Instruction.cacheKey!, toDisk: false)
        imageRepository.storeImage(ShieldImage.us101.image, forKey: us101Instruction.cacheKey!, toDisk: false)

        NavigationSettings.shared.distanceUnit = .mile
    }

    override func tearDown() {
        let semaphore = DispatchSemaphore(value: 0)
        imageRepository.resetImageCache {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")

        super.tearDown()
    }

    func testSinglelinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let instructions: [VisualInstruction.Component] = [
            .text(text: .init(text: "US 45", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "/", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "Chicago", abbreviation: nil, abbreviationPriority: 0)),
        ]

        view.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: instructions, secondaryInstruction: nil))

        verify(view)
    }

    func testMultilinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let instructions: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "US 45 / Chicago / US 45 / Chicago", abbreviation: nil, abbreviationPriority: 0)),
        ]

        view.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: instructions, secondaryInstruction: nil))

        verify(view)
    }

    func testSinglelinePrimaryAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "South", abbreviation: nil, abbreviationPriority: 0)),
        ]
        let secondary = [VisualInstruction.Component.text(text: .init(text: "US 45 / Chicago", abbreviation: nil, abbreviationPriority: 0))]

        view.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: primary, secondaryInstruction: secondary))

        verify(view)
    }

    func testPrimaryShieldAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
        ]
        let secondary = [VisualInstruction.Component.text(text: .init(text: "Mountain View Test", abbreviation: nil, abbreviationPriority: 0))]

        view.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: primary, secondaryInstruction: secondary))

        verify(view)
    }

    func testAbbreviateInstructions() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "Drive", abbreviation: "Dr", abbreviationPriority: 0)),
            .text(text: .init(text: "Avenue", abbreviation: "Ave", abbreviationPriority: 5)),
            .text(text: .init(text: "West", abbreviation: "W", abbreviationPriority: 4)),
            .text(text: .init(text: "South", abbreviation: "S", abbreviationPriority: 3)),
            .text(text: .init(text: "East", abbreviation: "E", abbreviationPriority: 2)),
            .text(text: .init(text: "North", abbreviation: "N", abbreviationPriority: 1)),
        ]

        view.update(for: makeVisualInstruction(.continue, .straightAhead, primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testAbbreviateInstructionsIncludingDelimiter() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/", abbreviation: nil, abbreviationPriority: nil)),
            .text(text: .init(text: "10", abbreviation: nil, abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/", abbreviation: nil, abbreviationPriority: nil)),
            .text(text: .init(text: "15 North", abbreviation: "15 N", abbreviationPriority: 0)),
            .delimiter(text: .init(text: "/", abbreviation: nil, abbreviationPriority: nil)),
            .text(text: .init(text: "20 West", abbreviation: "20 W", abbreviationPriority: 1)),
        ]

        imageRepository.storeImage(ShieldImage.i280.image, forKey: primary.first!.cacheKey!)
        view.update(for: makeVisualInstruction(.continue, .straightAhead, primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testAbbreviateWestFremontAvenue() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)

        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .text(text: .init(text: "West", abbreviation: "W", abbreviationPriority: 0)),
            .text(text: .init(text: "Fremont", abbreviation: nil, abbreviationPriority: nil)),
            .text(text: .init(text: "Avenue", abbreviation: "Ave", abbreviationPriority: 1)),
        ]

        view.update(for: makeVisualInstruction(.continue, .straightAhead, primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testAdjacentShields() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)
        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/", abbreviation: nil, abbreviationPriority: nil)),
            .image(image: .init(imageBaseURL: ShieldImage.us101.baseURL), alternativeText: .init(text: "US-101", abbreviation: nil, abbreviationPriority: nil)),
        ]

        view.update(for: makeVisualInstruction(.continue, .straightAhead, primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testInstructionsAndNextInstructions() {
        let view = UIView()
        view.backgroundColor = .white
        let instructionsBannerView = instructionsView()
        let nextBannerViewFrame = CGRect(x: 0, y: instructionsBannerView.frame.maxY, width: instructionsBannerView.bounds.width, height: 44)
        let nextBannerView = NextBannerView(frame: nextBannerViewFrame)
        nextBannerView.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(instructionsBannerView)
        view.addSubview(nextBannerView)
        view.frame = CGRect(origin: .zero, size: CGSize(width: nextBannerViewFrame.width, height: nextBannerViewFrame.maxY))

        instructionsBannerView.maneuverView.isStart = true
        instructionsBannerView.distance = 482

        let primary = [
            VisualInstruction.Component.image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
        ]
        let secondary = [VisualInstruction.Component.text(text: .init(text: "US 45 / Chicago", abbreviation: nil, abbreviationPriority: 0))]

        instructionsBannerView.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: primary, secondaryInstruction: secondary))

        let primaryThen = [
            VisualInstruction.Component.image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
        ]
        let primaryThenInstruction = VisualInstruction(text: nil, maneuverType: .none, maneuverDirection: .none, components: primaryThen)

        nextBannerView.instructionLabel.instruction = primaryThenInstruction
        nextBannerView.maneuverView.backgroundColor = .clear
        nextBannerView.maneuverView.isEnd = true

        verify(view)
    }

    func testLongDistance() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        NavigationSettings.shared.distanceUnit = .kilometer
        view.distanceFormatter.locale = Locale(identifier: "zh-Hans")
        view.distance = 1000 * 999

        let primary = [VisualInstruction.Component.text(text: .init(text: "中国 安徽省 宣城市 郎溪县", abbreviation: nil, abbreviationPriority: nil))]
        view.update(for: makeVisualInstruction(.continue, .straightAhead, primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testSweEngLongDistance() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)

        NavigationSettings.shared.distanceUnit = .mile
        view.distanceFormatter.locale = Locale(identifier: "sv-se")
        view.distance = 1000 * 999

        let primary = [VisualInstruction.Component.text(text: .init(text: "Lorem Ipsum / Dolor Sit Amet", abbreviation: nil, abbreviationPriority: nil))]
        view.update(for: makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testUkrainianLongDistance() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)

        NavigationSettings.shared.distanceUnit = .mile
        view.distanceFormatter.locale = Locale(identifier: "uk-UA")
        view.distance = 1000 * 999

        let primary = [VisualInstruction.Component.text(text: .init(text: "Lorem Ipsum / Dolor Sit Amet", abbreviation: nil, abbreviationPriority: nil))]
        view.update(for: makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))

        verify(view)
    }

    func testExitShields() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        let view = instructionsView()
        styleInstructionsView(view)
        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .exit(text: .init(text: "Exit", abbreviation: nil, abbreviationPriority: 0)),
            .exitCode(text: .init(text: "123A", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "Main Street", abbreviation: "Main St", abbreviationPriority: 0)),
        ]

        let secondary = VisualInstruction.Component.text(text: .init(text: "Anytown Avenue", abbreviation: "Anytown Ave", abbreviationPriority: 0))

        DayStyle().apply()
        window.addSubview(view)

        view.update(for: makeVisualInstruction(.takeOffRamp, .right, primaryInstruction: primary, secondaryInstruction: [secondary]))
        verify(view)
    }

    func testGenericShields() {
        let window = UIWindow(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        let view = instructionsView()
        styleInstructionsView(view)
        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: nil), alternativeText: .init(text: "ANK 1", abbreviation: nil, abbreviationPriority: nil)),
            .text(text: .init(text: "Ankh-Morpork 1", abbreviation: nil, abbreviationPriority: nil)),
        ]

        let secondary = [VisualInstruction.Component.text(text: .init(text: "Vetinari Way", abbreviation: nil, abbreviationPriority: nil))]

        window.addSubview(view)
        DayStyle().apply()

        view.update(for: makeVisualInstruction(.reachFork, .right, primaryInstruction: primary, secondaryInstruction: secondary))
        verify(view)
    }
}

extension InstructionsBannerViewSnapshotTests {
    // UIAppearance proxy do not work in unit test environment so we have to style manually
    func styleInstructionsView(_ view: InstructionsBannerView) {
        view.backgroundColor = .white
        view.maneuverView.backgroundColor = #colorLiteral(red: 0.5882352941, green: 0.5882352941, blue: 0.5882352941, alpha: 0.5)
        view.distanceLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5)
        view.primaryLabel.backgroundColor = #colorLiteral(red: 0.5882352941, green: 0.5882352941, blue: 0.5882352941, alpha: 0.5)
        view.secondaryLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5)
        view.dividerView.backgroundColor = .red
        view._separatorView.backgroundColor = .red
        view.stepListIndicatorView.layer.opacity = 0.25
        view.stepListIndicatorView.gradientColors = [.gray, .lightGray, .gray]

        view.distanceLabel.valueFont = UIFont.systemFont(ofSize: 24)
        view.distanceLabel.unitFont = UIFont.systemFont(ofSize: 14)
        view.primaryLabel.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        view.secondaryLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
    }
}
