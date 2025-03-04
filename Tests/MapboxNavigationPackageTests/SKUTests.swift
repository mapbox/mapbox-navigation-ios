import MapboxCommon_Private
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationUIKit
import TestHelper
import XCTest

#if DEBUG
class SKUTests: TestCase {
    fileprivate var urlSessionSpy: URLSessionSpy!
    var expectedSkuToken: String!

    override func setUp() {
        super.setUp()

        urlSessionSpy = URLSessionSpy()
        expectedSkuToken = UUID().uuidString
        billingServiceMock.onGetSKUTokenIfValid = { _ in
            self.expectedSkuToken
        }
    }

    var billingHandler: BillingHandler {
        navigationProvider.billingHandler
    }

    func testBillingHandlerSkuToken() {
        XCTAssertEqual(billingHandler.serviceSkuToken, "")
        billingHandler.beginBillingSession(for: .freeDrive, uuid: .init())
        let billingSkuToken = billingHandler.serviceSkuToken

        XCTAssertEqual(billingSkuToken, expectedSkuToken)
    }

    func testSpeechSynthesizerSKU() async {
        let skuTokenProvider = billingHandler.skuTokenProvider()
        let speechSynthesizer = SpeechSynthesizer(
            apiConfiguration: .mock(),
            skuTokenProvider: skuTokenProvider,
            urlSession: urlSessionSpy
        )
        let speechOptions = SpeechOptions(text: "text", locale: .current)
        _ = try? await speechSynthesizer.audioData(with: speechOptions)
        let token = urlSessionSpy.passedRequest?.url?.queryItem("sku")?.value
        XCTAssertEqual(token, "")
        navigationProvider.billingHandler.beginBillingSession(for: .freeDrive, uuid: .init())

        _ = try? await speechSynthesizer.audioData(with: speechOptions)
        let tokenWithSession = urlSessionSpy.passedRequest?.url?.queryItem("sku")?.value
        XCTAssertEqual(tokenWithSession, expectedSkuToken)
    }

    func testSKUTokensMatch() {
        billingHandler.beginBillingSession(for: .freeDrive, uuid: .init())
        let skuToken = "mocked token"
        billingServiceMock.onGetSKUTokenIfValid = { _ in skuToken }

        let viewController = TokenTestViewController(billingHandler: billingHandler)
        let tokenExpectation = XCTestExpectation(description: "All tokens should be fetched")
        viewController.tokenExpectation = tokenExpectation

        viewController.simulatateViewControllerPresented()

        wait(for: [tokenExpectation], timeout: 5)

        XCTAssertNotEqual(viewController.mapViewToken, viewController.serviceSkuToken)
        XCTAssertEqual(viewController.serviceSkuToken, skuToken)
    }

    fileprivate class URLSessionSpy: URLSession {
        var passedRequest: URLRequest?

        override func dataTask(
            with request: URLRequest,
            completionHandler: @escaping @Sendable (Foundation.Data?, URLResponse?, Error?) -> Void
        ) -> URLSessionDataTask {
            passedRequest = request
            return URLSessionDataTaskSpy(completionHandler: completionHandler)
        }
    }

    fileprivate class URLSessionDataTaskSpy: URLSessionDataTask {
        typealias CompletionHandler = (Foundation.Data?, URLResponse?, Error?) -> Void
        private let completionHandler: CompletionHandler

        init(completionHandler: @escaping CompletionHandler) {
            self.completionHandler = completionHandler
        }

        override func resume() {
            completionHandler(nil, nil, nil)
        }

        override func cancel() {}
    }
}
#endif
