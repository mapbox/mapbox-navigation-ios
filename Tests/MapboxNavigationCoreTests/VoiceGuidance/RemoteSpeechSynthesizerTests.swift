import _MapboxNavigationTestHelpers
import MapboxDirections
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import XCTest

final class RemoteSpeechSynthesizerTests: XCTestCase {
    private var urlSessionStub: URLSessionStub!
    private var synthesizer: RemoteSpeechSynthesizer!

    private static let accessToken = "pk.test-access-token"
    private static let apiEndpoint = URL(string: "https://api.mapbox.com")!
    private let defaultOptions = SpeechOptions(text: "Turn left", locale: Locale(identifier: "en-US"))

    override func setUp() {
        super.setUp()
        urlSessionStub = URLSessionStub()
        synthesizer = RemoteSpeechSynthesizer(
            apiConfiguration: .mock(accessToken: Self.accessToken, host: Self.apiEndpoint),
            skuTokenProvider: .init(skuToken: { "test-sku" }),
            urlSession: urlSessionStub
        )
    }

    // MARK: - URL Path

    func testPathPrefixIsVoiceV1Speak() async {
        await fireRequest()
        XCTAssertTrue(capturedPath?.hasPrefix("/voice/v1/speak/") == true)
    }

    func testURLUsesConfiguredEndpoint() async {
        let customSynthesizer = RemoteSpeechSynthesizer(
            apiConfiguration: .mock(accessToken: Self.accessToken, host: URL(string: "https://staging.mapbox.com")!),
            skuTokenProvider: .init(skuToken: { nil }),
            urlSession: urlSessionStub
        )
        await fireRequest(using: customSynthesizer)
        XCTAssertEqual(capturedURL?.host, "staging.mapbox.com")
    }

    func testDecodedPathContainsOriginalPlainText() async {
        let text = "Turn left onto Main Street"
        await fireRequest(SpeechOptions(text: text, locale: Locale(identifier: "en-US")))
        XCTAssertTrue(capturedPercentEncodedPath?.removingPercentEncoding?.hasSuffix(text) == true)
    }

    func testDecodedPathContainsOriginalSSML() async {
        let ssml = "<speak>Turn left</speak>"
        await fireRequest(SpeechOptions(ssml: ssml, locale: Locale(identifier: "en-US")))
        XCTAssertTrue(capturedPercentEncodedPath?.removingPercentEncoding?.hasSuffix(ssml) == true)
    }

    func testAmpersandInPlainTextIsPercentEncodedInPath() async {
        await fireRequest(SpeechOptions(text: "Barnes & Noble", locale: Locale(identifier: "en-US")))
        XCTAssertTrue(
            capturedPercentEncodedPath?.contains("%26") == true,
            "& must be percent-encoded as %26 in URL path"
        )
        XCTAssertFalse(capturedPercentEncodedPath?.contains("&") == true, "raw & must not appear in URL path")
    }

    func testAmpersandInSSMLIsPercentEncodedInPath() async {
        let ssml = "<speak>Turn left toward <say-as>Chili&apos;s Bar &amp; Grill</say-as></speak>"
        await fireRequest(SpeechOptions(ssml: ssml, locale: Locale(identifier: "en-US")))
        // & in XML entities must be encoded so they don't appear raw in the URL path
        XCTAssertFalse(capturedPercentEncodedPath?.contains("&amp;") == true, "&amp; must not appear raw in URL path")
        XCTAssertFalse(capturedPercentEncodedPath?.contains("&apos;") == true, "&apos; must not appear raw in URL path")
        // After decoding the path, the original SSML must survive intact
        let decoded = capturedPercentEncodedPath?.removingPercentEncoding
        XCTAssertTrue(decoded?.contains("&amp;") == true, "SSML &amp; entity must survive round-trip through URL path")
        XCTAssertTrue(
            decoded?.contains("&apos;") == true,
            "SSML &apos; entity must survive round-trip through URL path"
        )
    }

    func testSlashInTextIsPercentEncodedInPath() async {
        await fireRequest(SpeechOptions(text: "Take US-101/I-5", locale: Locale(identifier: "en-US")))
        XCTAssertTrue(
            capturedPercentEncodedPath?.contains("%2F") == true,
            "/ must be percent-encoded as %2F in URL path"
        )
    }

    // MARK: - Real-world SSML inputs

    func testRealWorldSSMLInputsHaveNoRawAmpersandInEncodedPath() async {
        for (i, ssml) in Self.realWorldSSMLInputs.enumerated() where ssml.contains("&") {
            await fireRequest(SpeechOptions(ssml: ssml, locale: Locale(identifier: "en-US")))
            XCTAssertFalse(
                capturedPercentEncodedPath?.contains("&") == true,
                "input \(i + 1): raw '&' must not appear in percent-encoded URL path"
            )
        }
    }

    func testRealWorldSSMLInputsRoundTripThroughURLPath() async {
        for (i, ssml) in Self.realWorldSSMLInputs.enumerated() {
            await fireRequest(SpeechOptions(ssml: ssml, locale: Locale(identifier: "en-US")))
            XCTAssertTrue(
                capturedPercentEncodedPath?.removingPercentEncoding?.hasSuffix(ssml) == true,
                "input \(i + 1): decoded URL path must end with the original SSML"
            )
        }
    }

    // MARK: - Query Parameters: textType

    func testTextTypeIsTextForPlainTextOptions() async {
        await fireRequest(SpeechOptions(text: "Turn left", locale: Locale(identifier: "en-US")))
        XCTAssertEqual(queryItem("textType"), "text")
    }

    func testTextTypeIsSSMLForSSMLOptions() async {
        await fireRequest(SpeechOptions(ssml: "<speak>Turn left</speak>", locale: Locale(identifier: "en-US")))
        XCTAssertEqual(queryItem("textType"), "ssml")
    }

    // MARK: - Query Parameters: language

    func testLanguageMatchesLocaleIdentifier() async {
        await fireRequest(SpeechOptions(text: "Turn left", locale: Locale(identifier: "fr-FR")))
        XCTAssertEqual(queryItem("language"), "fr-FR")
    }

    // MARK: - Query Parameters: outputFormat

    func testOutputFormatIsMP3() async {
        await fireRequest()
        XCTAssertEqual(queryItem("outputFormat"), "mp3")
    }

    // MARK: - Query Parameters: gender

    func testGenderIsOmittedWhenNeuter() async {
        var options = defaultOptions
        options.speechGender = .neuter
        await fireRequest(options)
        XCTAssertNil(queryItem("gender"), "gender param must be absent when .neuter")
    }

    func testGenderIsPresentWhenFemale() async {
        var options = defaultOptions
        options.speechGender = .female
        await fireRequest(options)
        XCTAssertEqual(queryItem("gender"), "female")
    }

    func testGenderIsPresentWhenMale() async {
        var options = defaultOptions
        options.speechGender = .male
        await fireRequest(options)
        XCTAssertEqual(queryItem("gender"), "male")
    }

    // MARK: - Query Parameters: auth

    func testAccessTokenFromConfiguration() async {
        await fireRequest()
        XCTAssertEqual(queryItem("access_token"), Self.accessToken)
    }

    func testSKUTokenIsIncludedWhenProviderReturnsValue() async {
        let expectedSKU = "test-sku-token"
        let synth = makeSynthesizer(sku: { expectedSKU })
        await fireRequest(using: synth)
        XCTAssertEqual(queryItem("sku"), expectedSKU)
    }

    func testSKUTokenIsOmittedWhenProviderReturnsNil() async {
        let synth = makeSynthesizer(sku: { nil })
        await fireRequest(using: synth)
        XCTAssertNil(queryItem("sku"), "sku param must be absent when provider returns nil")
    }

    // MARK: - Response Handling

    func testReturnsAudioDataOnSuccess() async throws {
        let expectedData = "audio-bytes".data(using: .utf8)!
        urlSessionStub.stub(data: expectedData, response: HTTPURLResponse(
            url: Self.apiEndpoint, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "audio/mpeg"]
        )!)
        let result = try await synthesizer.audioData(with: defaultOptions)
        XCTAssertEqual(result, expectedData)
    }

    func testThrowsTransportErrorOnURLError() async {
        urlSessionStub.stub(error: URLError(.notConnectedToInternet))
        do {
            _ = try await synthesizer.audioData(with: defaultOptions)
            XCTFail("Expected transportError to be thrown")
        } catch SpeechErrorApiError.transportError(let underlying) {
            XCTAssertEqual(underlying.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testThrowsRateLimitedOn429Response() async {
        let resetTimestamp = "1700000000"
        urlSessionStub.stub(
            data: #"{"message":"Rate limited"}"#.data(using: .utf8)!,
            response: HTTPURLResponse(
                url: Self.apiEndpoint, statusCode: 429, httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Rate-Limit-Limit": "100",
                    "X-Rate-Limit-Interval": "3600",
                    "X-Rate-Limit-Reset": resetTimestamp,
                ]
            )!
        )
        do {
            _ = try await synthesizer.audioData(with: defaultOptions)
            XCTFail("Expected rateLimited to be thrown")
        } catch SpeechErrorApiError.rateLimited(let interval, let limit, let resetTime) {
            XCTAssertEqual(limit, 100)
            XCTAssertEqual(interval, 3600)
            XCTAssertEqual(resetTime, Date(timeIntervalSince1970: Double(resetTimestamp)!))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPassesThroughSuccessfullyWhenResponseCodeIsOk() async throws {
        urlSessionStub.stub(
            data: #"{"code":"Ok"}"#.data(using: .utf8)!,
            response: HTTPURLResponse(
                url: Self.apiEndpoint, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )
        _ = try await synthesizer.audioData(with: defaultOptions)
    }

    func testThrowsServerErrorForErrorJSON() async {
        urlSessionStub.stub(
            data: #"{"code":"Unauthorized","message":"Invalid token"}"#.data(using: .utf8)!,
            response: HTTPURLResponse(
                url: Self.apiEndpoint, statusCode: 401, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )
        do {
            _ = try await synthesizer.audioData(with: defaultOptions)
            XCTFail("Expected serverError to be thrown")
        } catch SpeechErrorApiError.serverError(_, let serverResponse) {
            XCTAssertEqual(serverResponse.message, "Invalid token")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Helpers

extension RemoteSpeechSynthesizerTests {
    private var capturedURL: URL? { urlSessionStub.capturedRequest?.url }
    private var capturedPath: String? { capturedURL?.path }
    private var capturedPercentEncodedPath: String? {
        guard let url = capturedURL else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?.percentEncodedPath
    }

    private func queryItem(_ name: String) -> String? {
        guard let url = capturedURL else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }

    /// Fires a request through the synthesizer and asserts the stub captured it.
    private func fireRequest(_ options: SpeechOptions? = nil, using synth: RemoteSpeechSynthesizer? = nil) async {
        _ = try? await (synth ?? synthesizer).audioData(with: options ?? defaultOptions)
        XCTAssertNotNil(capturedURL, "URLSessionStub must capture a request")
    }

    private func makeSynthesizer(sku: @escaping @Sendable () -> String?) -> RemoteSpeechSynthesizer {
        RemoteSpeechSynthesizer(
            apiConfiguration: .mock(accessToken: Self.accessToken, host: Self.apiEndpoint),
            skuTokenProvider: .init(skuToken: sku),
            urlSession: urlSessionStub
        )
    }
}

// MARK: - Real-world SSML input corpus

extension RemoteSpeechSynthesizerTests {
    // swiftlint:disable line_length
    static let realWorldSSMLInputs: [String] = [
        // Japanese: jeita phoneme with &apos; and &amp; in ph attribute
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">100メートル先、<phoneme alphabet=\"jeita\" ph=\"ｳﾒﾀﾞﾗ&apos;ﾝﾌﾟ%:ﾋｶﾞ&amp;ｼ%\">梅田ランプ東</phoneme>を左方向です。</prosody></amazon:effect></speak>",
        // English: plain turn instruction
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn right onto California Street</prosody></amazon:effect></speak>",
        // Chinese: say-as address tags
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">沿 <say-as interpret-as=\"address\">德祥路</say-as> 向东行驶。 然后 右转进入 <say-as interpret-as=\"address\">海專路</say-as>。</prosody></amazon:effect></speak>",
        // Japanese: jeita phoneme with &amp; and &apos; in ph attribute
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">300メートル先、<phoneme alphabet=\"jeita\" ph=\"ﾋｶﾞ&amp;ｼﾘ&apos;ﾝｶﾝ ﾆﾁｮｰﾒ\">東林間二丁目</phoneme>を右方向です。</prosody></amazon:effect></speak>",
        // English: route number with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Continue on <say-as interpret-as=\"address\">R-213</say-as> for a half mile.</prosody></amazon:effect></speak>",
        // English: street name with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn right onto <say-as interpret-as=\"address\">South Pacific Avenue</say-as>.</prosody></amazon:effect></speak>",
        // English: stay-on instruction with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 400 meters, Turn left to stay on <say-as interpret-as=\"address\">West Creek Circle</say-as>.</prosody></amazon:effect></speak>",
        // Dutch: legal speed-camera warning without drc effect
        "<speak>Let op! Vanwege regelgeving in Duitsland waarschuwen wij niet voor snelheidscontroles.</speak>",
        // English: distance + street with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Drive south on <say-as interpret-as=\"address\">Chisholm Road</say-as> for 1.5 miles.</prosody></amazon:effect></speak>",
        // English: UK road name with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn right onto <say-as interpret-as=\"address\">Hookstone Chase</say-as>.</prosody></amazon:effect></speak>",
        // English: two-step instruction
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Drive east on <say-as interpret-as=\"address\">Alberta Street</say-as>. Then Turn left onto <say-as interpret-as=\"address\">South Grand Boulevard</say-as>.</prosody></amazon:effect></speak>",
        // English: destination arrival
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 700 feet, Your destination will be on the right.</prosody></amazon:effect></speak>",
        // English: business name with literal & in text content
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn left. Then Sake Japanese Steak House & Sushi Bar will be on the right.</prosody></amazon:effect></speak>",
        // English: quarter-mile with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In a quarter mile, Turn left onto <say-as interpret-as=\"address\">Braddock Avenue</say-as>.</prosody></amazon:effect></speak>",
        // English: two-step with 500 m lookahead
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Drive northeast on <say-as interpret-as=\"address\">Elizabeth Avenue</say-as>. Then, in 500 meters, Turn right onto <say-as interpret-as=\"address\">Rodney Street</say-as>.</prosody></amazon:effect></speak>",
        // Chinese: two-step with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">沿 <say-as interpret-as=\"address\">大墩十街</say-as> 向西行驶。 然后 右转进入 <say-as interpret-as=\"address\">文心路一段</say-as>。</prosody></amazon:effect></speak>",
        // Japanese: two jeita phoneme elements, one with &apos; and &amp;
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">左方向、<phoneme alphabet=\"jeita\" ph=\"ｺｸﾄﾞｰ ﾋｬｸ ﾅﾅ&apos;ｼﾞｭｰ ﾛｸｺﾞ&amp;ｰｾﾝ\">国道176号線</phoneme>, <phoneme alphabet=\"jeita\" ph=\"ﾐﾄﾞｰｽｼﾞ\">御堂筋</phoneme>を進みます。。その先目的地は左側です。</prosody></amazon:effect></speak>",
        // Dutch: legal speed-camera warning (France)
        "<speak>Let op! Vanwege regelgeving in Frankrijk waarschuwen wij niet voor snelheidscontroles.</speak>",
        // English: two-step turn sequence
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn right onto <say-as interpret-as=\"address\">Autunno Street</say-as>. Then Turn left.</prosody></amazon:effect></speak>",
        // Japanese: jeita phoneme with % in ph, no XML entities
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\"><phoneme alphabet=\"jeita\" ph=\"ﾀﾂﾐｼﾞｬﾝｸ%ｼｮﾝ\">辰巳JCT</phoneme>を右方向です。</prosody></amazon:effect></speak>",
        // English: IPA phoneme combined with say-as, roundabout exit
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Drive south on <phoneme alphabet=\"ipa\" ph=\"ˌwəʊkɪŋ ˈrəʊd\">Woking Road</phoneme>, <say-as interpret-as=\"address\">A320</say-as>. Then Enter the roundabout and take the 4th exit onto <phoneme alphabet=\"ipa\" ph=\"ˌwəʊkɪŋ ˈrəʊd\">Woking Road</phoneme>.</prosody></amazon:effect></speak>",
        // English: county route with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 2 miles, Turn left onto <say-as interpret-as=\"address\">County Route N21 70</say-as>.</prosody></amazon:effect></speak>",
        // English: no say-as, plain prosody
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 2 miles turn right onto South Birch Street</prosody></amazon:effect></speak>",
        // English: half-mile with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In a half mile, Turn left onto <say-as interpret-as=\"address\">Boxwood Lane</say-as>.</prosody></amazon:effect></speak>",
        // Albanian: multiple say-as including roundabout exit
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Drive east on <say-as interpret-as=\"address\">Sadulla Brestovci</say-as>. Then Enter <say-as interpret-as=\"address\">Ibrahim Rugova</say-as> and take the 2nd exit onto <say-as interpret-as=\"address\">Mulla Idrizi</say-as>.</prosody></amazon:effect></speak>",
        // English: business name with literal & in text content
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn right onto <say-as interpret-as=\"address\">Oxford Street</say-as>. Then, in 60 meters, GH Kebabs, Pizza & Pida's will be on the left.</prosody></amazon:effect></speak>",
        // English: two-step with quarter-mile lookahead
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Drive west on <say-as interpret-as=\"address\">Old Coast Highway</say-as>. Then, in a quarter mile, Turn left onto <say-as interpret-as=\"address\">South Salinas Street</say-as>.</prosody></amazon:effect></speak>",
        // Russian: Cyrillic instruction with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Поверните налево на <say-as interpret-as=\"address\">New Lots Avenue</say-as>.</prosody></amazon:effect></speak>",
        // English: simple turn with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn left onto <say-as interpret-as=\"address\">Crystal Brook Way</say-as>.</prosody></amazon:effect></speak>",
        // English: lane change with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Move left onto <say-as interpret-as=\"address\">Parkneuk Road</say-as>.</prosody></amazon:effect></speak>",
        // English: quarter-of-a-mile phrasing
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In a quarter of a mile, Turn right onto <say-as interpret-as=\"address\">Castle Street</say-as>.</prosody></amazon:effect></speak>",
        // English: two-step without say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Head south on Taylor Street, then turn right onto California Street</prosody></amazon:effect></speak>",
        // Chinese: distance prefix before turn
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">沿 <say-as interpret-as=\"address\">和平路</say-as> 向北行驶。 80 米后， 右转进入 <say-as interpret-as=\"address\">民生東路</say-as>。</prosody></amazon:effect></speak>",
        // Dutch: legal speed-camera warning (Duitsland, second occurrence)
        "<speak>Let op! Vanwege regelgeving in Duitsland waarschuwen wij niet voor snelheidscontroles.</speak>",
        // English: simple left turn with say-as
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn left onto <say-as interpret-as=\"address\">Jimmy Camp Road</say-as>.</prosody></amazon:effect></speak>",
        // English: business name with literal & in text content
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn right. Then Pho Fresh Alley & Boba Tea will be on the left.</prosody></amazon:effect></speak>",
        // English: turn-then-turn sequence
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn left onto <say-as interpret-as=\"address\">Cortelyou Road</say-as>. Then Turn right.</prosody></amazon:effect></speak>",
        // Japanese: CJK text only, no phoneme elements
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">70先、左に曲がり、県道３０号線 を進む</prosody></amazon:effect></speak>",
        // Japanese: jeita phoneme with &apos; and &amp; in ph attribute
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">70メートル先、右方向、<phoneme alphabet=\"jeita\" ph=\"ｹﾝﾄﾞｰ ﾆ&apos;ｼﾞｭｰ ｲﾁｺﾞ&amp;ｰｾﾝ\">県道21号線</phoneme>を進みます。</prosody></amazon:effect></speak>",
        // English: feet-based distance
        "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 900 feet, Turn right.</prosody></amazon:effect></speak>",
    ]
    // swiftlint:enable line_length
}

// MARK: - URLSessionStub

// URLSession.data(for:) is implemented in the Swift Foundation overlay as an async wrapper
// around dataTask(with:completionHandler:). This stub intercepts at that layer. If a future
// SDK version makes data(for:) a separate native-async path, capturedRequest will be nil and
// every test that calls XCTAssertNotNil(capturedURL) will fail loudly rather than silently passing.
private final class URLSessionStub: URLSession, @unchecked Sendable {
    private(set) var capturedRequest: URLRequest?
    private var stubbedData: Data?
    private var stubbedResponse: URLResponse?
    private var stubbedError: Error?

    func stub(data: Data, response: URLResponse) {
        stubbedData = data
        stubbedResponse = response
        stubbedError = nil
    }

    func stub(error: Error) {
        stubbedData = nil
        stubbedResponse = nil
        stubbedError = error
    }

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        capturedRequest = request
        return DataTaskStub(
            data: stubbedData,
            response: stubbedResponse,
            error: stubbedError,
            completionHandler: completionHandler
        )
    }
}

private final class DataTaskStub: URLSessionDataTask, @unchecked Sendable {
    private let stubbedData: Data?
    private let stubbedResponse: URLResponse?
    private let stubbedError: Error?
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void

    init(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        self.stubbedData = data
        self.stubbedResponse = response
        self.stubbedError = error
        self.completionHandler = completionHandler
    }

    override func resume() { completionHandler(stubbedData, stubbedResponse, stubbedError) }
    override func cancel() {}
}
