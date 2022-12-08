import XCTest
import TestHelper
import SnapshotTesting
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class InstructionsBannerViewSnapshotTests: InstructionBannerTest {
    let asyncTimeout: TimeInterval = 2.0

    override func setUp() {
        super.setUp()
        isRecording = false

        let i280Representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL)
        let us101Representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.us101.baseURL)

        cacheLegacyIcon(with: i280Representation, shieldImage: .i280)
        cacheLegacyIcon(with: us101Representation, shieldImage: .us101)
        NavigationSettings.shared.distanceUnit = .mile
        DayStyle().apply()
    }

    override func tearDown() {
        super.tearDown()
        clearDiskCache()
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }
    
    func testSinglelinePrimaryAndSecondaryWithShield() {
        cacheSprite(for: .navigationDay)
        
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let i280Shield = VisualInstruction.Component.ShieldRepresentation(baseURL: spriteRepository.baseURL, name: "us-interstate", textColor: "white", text: "280")
        let i280Representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: i280Shield)
        
        let primary: [VisualInstruction.Component] = [
            .image(image: i280Representation, alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "South", abbreviation: nil, abbreviationPriority: 0)),
        ]
        let secondary = [VisualInstruction.Component.text(text: .init(text: "US 45 / Chicago", abbreviation: nil, abbreviationPriority: 0))]

        view.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: primary, secondaryInstruction: secondary))
        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }
    
    func testSinglelinePrimaryAndSecondaryWithNightShield() {
        cacheSprite(for: .navigationNight)
        
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let i280Shield = VisualInstruction.Component.ShieldRepresentation(baseURL: spriteRepository.baseURL, name: "us-interstate", textColor: "white", text: "280")
        let i280Representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: i280Shield)
        
        let primary: [VisualInstruction.Component] = [
            .image(image: i280Representation, alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
            .text(text: .init(text: "South", abbreviation: nil, abbreviationPriority: 0)),
        ]
        let secondary = [VisualInstruction.Component.text(text: .init(text: "US 45 / Chicago", abbreviation: nil, abbreviationPriority: 0))]

        view.update(for: makeVisualInstruction(.turn, .right, primaryInstruction: primary, secondaryInstruction: secondary))
        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        view.update(for: makeVisualInstruction(.continue, .straightAhead, primaryInstruction: primary, secondaryInstruction: nil))

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
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

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }

    func testSweEngLongDistance() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)

        NavigationSettings.shared.distanceUnit = .mile
        view.distanceFormatter.locale = Locale(identifier: "sv-se")
        view.distance = 1000 * 999

        let primary = [VisualInstruction.Component.text(text: .init(text: "Lorem Ipsum / Dolor Sit Amet", abbreviation: nil, abbreviationPriority: nil))]
        view.update(for: makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }

    func testUkrainianLongDistance() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)

        NavigationSettings.shared.distanceUnit = .mile
        view.distanceFormatter.locale = Locale(identifier: "uk-UA")
        view.distance = 1000 * 999

        let primary = [VisualInstruction.Component.text(text: .init(text: "Lorem Ipsum / Dolor Sit Amet", abbreviation: nil, abbreviationPriority: nil))]
        view.update(for: makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))

        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }

    func testExitShields() {
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

        view.update(for: makeVisualInstruction(.takeOffRamp, .right, primaryInstruction: primary, secondaryInstruction: [secondary]))
        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }

    func testGenericShields() {
        let view = instructionsView()
        styleInstructionsView(view)
        view.maneuverView.isStart = true
        view.distance = 482

        let primary: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: nil), alternativeText: .init(text: "ANK 1", abbreviation: nil, abbreviationPriority: nil)),
            .text(text: .init(text: "Ankh-Morpork 1", abbreviation: nil, abbreviationPriority: nil)),
        ]

        let secondary = [VisualInstruction.Component.text(text: .init(text: "Vetinari Way", abbreviation: nil, abbreviationPriority: nil))]

        DayStyle().apply()

        view.update(for: makeVisualInstruction(.reachFork, .right, primaryInstruction: primary, secondaryInstruction: secondary))
        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }
    
    func testGenericShieldAndExitViewWithCustomDayStyle() {
        
        class CustomDayStyle: DayStyle {
            
            required init() {
                super.init()
            }
            
            override func apply() {
                super.apply()
                
                let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
                PrimaryLabel.appearance(for: traitCollection).normalTextColor = UIColor.green
                SecondaryLabel.appearance(for: traitCollection).normalTextColor = UIColor.red
                
                GenericRouteShield.appearance(for: traitCollection).borderWidth = 1.0
                GenericRouteShield.appearance(for: traitCollection).foregroundColor = UIColor.blue
                GenericRouteShield.appearance(for: traitCollection).borderColor = UIColor.blue
                
                ExitView.appearance(for: traitCollection).borderWidth = 1.0
                ExitView.appearance(for: traitCollection).foregroundColor = UIColor.yellow
                ExitView.appearance(for: traitCollection).borderColor = UIColor.yellow
            }
        }
        
        let instructionsBannerView = instructionsView()
        styleInstructionsView(instructionsBannerView)
        instructionsBannerView.distance = 1400 // meters

        let primaryInstruction: [VisualInstruction.Component] = [
            .exitCode(text: .init(text: "15",
                                  abbreviation: nil,
                                  abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/",
                                   abbreviation: nil,
                                   abbreviationPriority: nil)),
            .image(image: .init(imageBaseURL: nil),
                   alternativeText: .init(text: "CTE",
                                          abbreviation: nil,
                                          abbreviationPriority: nil)),
        ]
        
        let secondaryInstruction: [VisualInstruction.Component] = [
            .image(image: .init(imageBaseURL: nil),
                   alternativeText: .init(text: "SLE",
                                          abbreviation: nil,
                                          abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/",
                                   abbreviation: nil,
                                   abbreviationPriority: nil)),
            .image(image: .init(imageBaseURL: nil),
                   alternativeText: .init(text: "TPE",
                                          abbreviation: nil,
                                          abbreviationPriority: nil)),
        ]
        
        CustomDayStyle().apply()
        
        let visualInstructionBanner = makeVisualInstruction(.takeOffRamp,
                                                            .right,
                                                            primaryInstruction: primaryInstruction,
                                                            secondaryInstruction: secondaryInstruction)
        
        instructionsBannerView.update(for: visualInstructionBanner)
        
        assertImageSnapshot(matching: instructionsBannerView,
                            as: .image(precision: 0.95))
    }
    
    func testGenericShieldAndExitViewHighlightColor() {
        class CustomDayStyle: DayStyle {
            
            required init() {
                super.init()
            }
            
            override func apply() {
                super.apply()
                
                let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
                // Check that PrimaryLabel.normalTextColor is not used
                PrimaryLabel.appearance(for: traitCollection).normalTextColor = UIColor.blue
                PrimaryLabel.appearance(for: traitCollection).textColorHighlighted = UIColor.green
                
                // Check that SecondaryLabel.textColorHighlighted is not used
                SecondaryLabel.appearance(for: traitCollection).normalTextColor = UIColor.red
                SecondaryLabel.appearance(for: traitCollection).textColorHighlighted = UIColor.yellow
                
                GenericRouteShield.appearance(for: traitCollection).highlightColor = UIColor.blue
                ExitView.appearance(for: traitCollection).highlightColor = UIColor.yellow
            }
        }
        
        let instructionsBannerView = instructionsView()
        styleInstructionsView(instructionsBannerView)
        instructionsBannerView.distance = 50
        
        let primaryInstruction: [VisualInstruction.Component] = [
            .exitCode(text: .init(text: "15",
                                  abbreviation: nil,
                                  abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/",
                                   abbreviation: nil,
                                   abbreviationPriority: nil)),
            .image(image: .init(imageBaseURL: nil),
                   alternativeText: .init(text: "CTE",
                                          abbreviation: nil,
                                          abbreviationPriority: nil)),
        ]
        
        let secondaryInstruction: [VisualInstruction.Component] = [
            .exitCode(text: .init(text: "15",
                                  abbreviation: nil,
                                  abbreviationPriority: nil)),
            .delimiter(text: .init(text: "/",
                                   abbreviation: nil,
                                   abbreviationPriority: nil)),
            .image(image: .init(imageBaseURL: nil),
                   alternativeText: .init(text: "CTE",
                                          abbreviation: nil,
                                          abbreviationPriority: nil)),
        ]
        
        instructionsBannerView.primaryLabel.showHighlightedTextColor = true
        instructionsBannerView.secondaryLabel.showHighlightedTextColor = false

        CustomDayStyle().apply()

        let visualInstructionBanner = makeVisualInstruction(.takeOffRamp,
                                                            .right,
                                                            primaryInstruction: primaryInstruction,
                                                            secondaryInstruction: secondaryInstruction)
        instructionsBannerView.update(for: visualInstructionBanner)

        assertImageSnapshot(matching: instructionsBannerView,
                            as: .image(precision: 0.95))
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

class InstructionBannerTest: TestCase {
    var spriteRepository: SpriteRepository!

    override func setUp() {
        super.setUp()

        spriteRepository = SpriteRepository(requestCache: URLCacheSpy(),
                                            derivedCache: BimodalImageCacheSpy())
    }

    func instructionsView(size: CGSize = .iPhone6Plus) -> InstructionsBannerView {
        let bannerHeight: CGFloat = 96
        let frame = CGRect(origin: .zero, size: CGSize(width: size.width, height: bannerHeight))
        let bannerView = InstructionsBannerView(frame: frame)
        bannerView.primaryLabel.spriteRepository = spriteRepository
        bannerView.secondaryLabel.spriteRepository = spriteRepository
        return bannerView
    }

    func makeVisualInstruction(_ maneuverType: ManeuverType = .arrive,
                               _ maneuverDirection: ManeuverDirection = .left,
                               primaryInstruction: [VisualInstruction.Component],
                               secondaryInstruction: [VisualInstruction.Component]?,
                               drivingSide: DrivingSide = .right) -> VisualInstructionBanner {
        return Fixture.makeVisualInstruction(maneuverType: maneuverType,
                                             maneuverDirection: maneuverDirection,
                                             primaryInstruction: primaryInstruction,
                                             secondaryInstruction: secondaryInstruction,
                                             drivingSide: drivingSide)
    }
    
    func cacheSprite(for styleURI: StyleURI = .navigationDay) {
        let shieldImage: ShieldImage = (styleURI == .navigationDay) ? .shieldDay : .shieldNight
        guard let styleID = spriteRepository.styleID(for: styleURI),
              let spriteRequestURL = spriteRepository.spriteURL(isImage: true, styleID: styleID),
              let infoRequestURL = spriteRepository.spriteURL(isImage: false, styleID: styleID),
              let spriteData = shieldImage.image.pngData() else {
                  XCTFail("Failed to form request URL.")
                  return
              }
        
        let spriteResponse = URLResponse(url: spriteRequestURL, mimeType: nil, expectedContentLength: spriteData.count, textEncodingName: nil)
        spriteRepository.requestCache.store( CachedURLResponse(response: spriteResponse, data: spriteData), for: spriteRequestURL)
        
        let infoData = Fixture.JSONFromFileNamed(name: "sprite-info")
        let infoResponse = URLResponse(url: infoRequestURL, mimeType: nil, expectedContentLength: infoData.count, textEncodingName: nil)
        spriteRepository.requestCache.store( CachedURLResponse(response: infoResponse, data: infoData), for: infoRequestURL)
    }
    
    func clearDiskCache() {
        let semaphore = DispatchSemaphore(value: 0)
        spriteRepository.resetCache() {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }
    
    func cacheLegacyIcon(with representation: VisualInstruction.Component.ImageRepresentation, shieldImage: ShieldImage) {
        guard let legacyURL = representation.imageURL(scale: VisualInstruction.Component.scale, format: .png),
              let data = shieldImage.image.pngData() else {
            XCTFail("Failed to cache legacy images.")
            return
        }
        let response = URLResponse(url: legacyURL, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        spriteRepository.requestCache.store(CachedURLResponse(response: response, data: data), for: legacyURL)
    }
}

