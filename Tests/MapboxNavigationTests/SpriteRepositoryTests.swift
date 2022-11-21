import XCTest
import MapboxDirections
import MapboxMaps
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class SpriteRepositoryTests: TestCase {
    var repository: SpriteRepository!

    var requestCache: URLCacheSpy!
    var derivedCache: BimodalImageCacheSpy!
    var imageDownloader: ReentrantImageDownloaderSpy!

    let spriteInfo = Fixture.JSONFromFileNamed(name: "sprite-info")

    override func setUp() {
        super.setUp()

        requestCache = URLCacheSpy()
        derivedCache = BimodalImageCacheSpy()
        imageDownloader = ReentrantImageDownloaderSpy()
        repository = SpriteRepository(imageDownloader: imageDownloader,
                                      requestCache: requestCache,
                                      derivedCache: derivedCache)
    }

    func storeData(styleType: StyleType = .day) {
        let scale = Int(VisualInstruction.Component.scale)
        let styleURI: StyleURI = (styleType == .day) ? .navigationDay : .navigationNight
        guard let styleID = repository.styleID(for: styleURI),
              let spriteRequestURL = repository.spriteURL(isImage: true, styleID: styleID),
              let infoRequestURL = repository.spriteURL(isImage: false, styleID: styleID),
              let legacyRequestURL = URL(string: ShieldImage.i280.baseURL.absoluteString + "@\(scale)x.png") else {
            XCTFail("Failed to form request URL.")
            return
        }
        imageDownloader.returnedDownloadResults[spriteRequestURL] = ShieldImage.shieldDay.image.pngData()
        imageDownloader.returnedDownloadResults[legacyRequestURL] = ShieldImage.i280.image.pngData()
        imageDownloader.returnedDownloadResults[infoRequestURL] = spriteInfo
    }
    
    func testDownLoadingSpriteInfo() {
        let fakeURL = URL(string: "http://an.image.url/spriteInfo.json")!
        imageDownloader.returnedDownloadResults[fakeURL] = spriteInfo

        let dataKey = "us-interstate-3"
        XCTAssertNil(repository.getSpriteInfo(styleURI: .navigationDay, with: dataKey))
        
        let semaphore = DispatchSemaphore(value: 0)
        var requestedData: Data?
        repository.downloadInfo(fakeURL) { (data) in
            requestedData = data
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")

        guard let data = requestedData else {
            XCTFail("Failed to download Sprite Info.")
            return
        }
        
        guard let spriteInfoDictionary = repository.parseSpriteInfo(data: data) else {
            XCTFail("Failed to parse Sprite Info.")
            return
        }
        
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        let spriteInfo = spriteInfoDictionary[dataKey]
        XCTAssertEqual(expectedInfo, spriteInfo, "Failed to retrieve Sprite info from cache.")
    }
    
    func testDownLoadingImage() {
        let fakeURL = URL(string: "http://an.image.url/sprite.png")!
        imageDownloader.returnedDownloadResults[fakeURL] = ShieldImage.i280.image.pngData()!

        XCTAssertNil(repository.getSpriteImage(styleURI: .navigationDay))
        
        let semaphore = DispatchSemaphore(value: 0)
        var requestedImage: UIImage?
        
        repository.downloadImage(imageURL: fakeURL) { (image) in
            requestedImage = image
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")
        
        XCTAssertNotNil(requestedImage)
        XCTAssertTrue((requestedImage?.isKind(of: UIImage.self))!)
    }
    
    func testGeneratingSpriteURL() {
        guard let styleID = repository.styleID(for: .navigationDay),
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken else {
            XCTFail("Failed to form request URL from SpriteRepository.")
            return
        }
        
        let scale = Int(VisualInstruction.Component.scale)
        let baseURLstring = repository.baseURL.absoluteString
        let spriteRequestURL = URL(string: baseURLstring + styleID + "/sprite@\(scale)x.png?access_token=" + accessToken)
        let infoRequestURL = URL(string: baseURLstring + styleID + "/sprite@\(scale)x?access_token=" + accessToken)
        
        let expetecSpriteRequestURL = repository.spriteURL(isImage: true, styleID: styleID)
        let expectedInfoRequestURL = repository.spriteURL(isImage: false, styleID: styleID)
        XCTAssertEqual(spriteRequestURL, expetecSpriteRequestURL, "Failed to generate Sprite request URL from SpriteRepository.")
        XCTAssertEqual(infoRequestURL, expectedInfoRequestURL, "Failed to generate Sprite info request URL from SpriteRepository.")
    }
    
    func testUpdateRepresentation() {
        storeData()
        
        let shield = VisualInstruction.Component.ShieldRepresentation(baseURL: repository.baseURL, name: "us-interstate", textColor: "white", text: "280")
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: shield)
        let dataKey = "us-interstate-3"
        
        XCTAssertNil(repository.getSpriteInfo(styleURI: .navigationDay))
        XCTAssertNil(repository.getSpriteImage(styleURI: .navigationDay))
        XCTAssertNil(repository.getLegacyShield(with: representation))
        
        let expectation = expectation(description: "Image Downloaded.")
        repository.updateRepresentation(for: representation) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let spriteInfo = repository.getSpriteInfo(styleURI: .navigationDay, with: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        let sprite = repository.getSpriteImage(styleURI: .navigationDay)
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!, "Failed to update the Sprite.")
        
        let legacyShield = repository.getLegacyShield(with: representation)
        XCTAssertNotNil(legacyShield)
        XCTAssertTrue((legacyShield?.isKind(of: UIImage.self))!, "Failed to download the legacy shield.")
        
        let shieldIcon = repository.roadShieldImage(from: shield)
        XCTAssertNotNil(shieldIcon)
        XCTAssertTrue((shieldIcon?.isKind(of: UIImage.self))!, "Failed to cut the shield icon.")
    }
    
    func testUpdateRepresentationOnDifferentDevices() {
        storeData()
        
        let shield = VisualInstruction.Component.ShieldRepresentation(baseURL: repository.baseURL, name: "us-interstate", textColor: "white", text: "280")
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: shield)
        
        let defaultExpectation = expectation(description: "Representation updated on default phone.")
        repository.updateRepresentation(for: representation) { _ in
            defaultExpectation.fulfill()
        }
        wait(for: [defaultExpectation], timeout: 3.0)
        
        var expectedCachedStyles: [UIUserInterfaceIdiom: StyleURI] = [.phone: .navigationDay]
        XCTAssertEqual(repository.userInterfaceIdiomStyles, expectedCachedStyles)
        var shieldIcon = repository.roadShieldImage(from: shield)
        XCTAssertNotNil(shieldIcon)
        
        let carPlayExpectation = expectation(description: "Representation updated on CarPlay.")
        repository.updateRepresentation(for: representation, idiom: .carPlay) { _ in
            carPlayExpectation.fulfill()
        }
        wait(for: [carPlayExpectation], timeout: 3.0)
        
        expectedCachedStyles = [.phone: .navigationDay, .carPlay: .navigationDay]
        XCTAssertEqual(repository.userInterfaceIdiomStyles, expectedCachedStyles, "Failed to use cached style data when no styleURI provided.")
        shieldIcon = repository.roadShieldImage(from: shield, idiom: .carPlay)
        XCTAssertNotNil(shieldIcon)
    }
    
    func testUpdateStyle() {
        let styleURI = StyleURI.navigationNight
        
        let expectation = expectation(description: "Style updated.")
        repository.updateStyle(styleURI: styleURI) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let defaultStyle = repository.userInterfaceIdiomStyles[.phone]
        XCTAssertEqual(styleURI, defaultStyle, "Failed to update the styleURI.")
    }
    
    func testUpdateStylesOnDifferentDevices() {
        storeData(styleType: .day)
        storeData(styleType: .night)
        
        var expectedCachedStyles = [UIUserInterfaceIdiom: StyleURI]()
        XCTAssertEqual(repository.userInterfaceIdiomStyles, expectedCachedStyles)
        
        let nightStyleURI = StyleURI.navigationNight
        let nightStyleExpectation = expectation(description: "Night style updated.")
        repository.updateStyle(styleURI: nightStyleURI) { _ in
            nightStyleExpectation.fulfill()
        }
        wait(for: [nightStyleExpectation], timeout: 3.0)
        
        expectedCachedStyles = [.phone : nightStyleURI]
        XCTAssertEqual(expectedCachedStyles, repository.userInterfaceIdiomStyles, "Failed to update styleURI for default phone.")
        XCTAssertNotNil(repository.getSpriteImage(styleURI: nightStyleURI), "Failed to download Sprite image for default phone.")
        
        let dayStyleURI = StyleURI.navigationDay
        let dayStyleExpectation = expectation(description: "Day style updated.")
        repository.updateStyle(styleURI: dayStyleURI, idiom: .carPlay) { _ in
            dayStyleExpectation.fulfill()
        }
        wait(for: [dayStyleExpectation], timeout: 3.0)
        
        expectedCachedStyles = [.phone: nightStyleURI, .carPlay: dayStyleURI]
        XCTAssertEqual(expectedCachedStyles, repository.userInterfaceIdiomStyles, "Failed to update the styleURI on CarPlay.")
        XCTAssertNotNil(repository.getSpriteImage(styleURI: nightStyleURI), "Failed to keep Sprite image for default phone.")
        XCTAssertNotNil(repository.getSpriteImage(styleURI: dayStyleURI), "Failed to download Sprite image for CarPlay.")
    }
    
    func testPartiallySpriteUpdate() {
        storeData()
        
        // Update representation of the repository and fully downloaded Sprite image and metadata.
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL)
        let dataKey = "us-interstate-3"
        
        var downloadExpectation = expectation(description: "Representation updated.")
        repository.updateRepresentation(for: representation) { _ in
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        var spriteInfo = repository.getSpriteInfo(styleURI: .navigationDay, with: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        // Partially update style of the repository after the representation update.
        let newStyleURI = StyleURI.navigationNight
        guard let newStyleID = repository.styleID(for: newStyleURI),
              let infoRequestURL = repository.spriteURL(isImage: false, styleID: newStyleID) else {
                  XCTFail("Failed to form request to update SpriteRepository.")
                  return
        }

        imageDownloader.returnedDownloadResults[infoRequestURL] = self.spriteInfo

        // Downloaded Sprite metadata without Sprite image to test the shield icon retrieval under poor network condition.
        downloadExpectation = expectation(description: "Sprite info updated.")
        repository.downloadInfo(infoRequestURL) { (_) in
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        
        // The Sprite info should be ready for current Sprite repository without matched Sprite image.
        spriteInfo = repository.getSpriteInfo(styleURI: newStyleURI, with: dataKey)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        XCTAssertNil(repository.getSpriteImage(styleURI: newStyleURI), "Failed to match the Sprite image with the spriteKey.")
    }

    func testResetCache() {
        repository.updateStyle(styleURI: StyleURI.navigationNight) { _ in }
        let complitionExpectation = expectation(description: "Should call completion")
        repository.resetCache() {
            complitionExpectation.fulfill()
        }

        XCTAssertTrue(derivedCache.clearMemoryCalled)
        XCTAssertTrue(derivedCache.clearDiskCalled)
        XCTAssertTrue(requestCache.clearCacheCalled)
        XCTAssertTrue(repository.userInterfaceIdiomStyles.isEmpty)

        waitForExpectations(timeout: 0.5)
    }

}
