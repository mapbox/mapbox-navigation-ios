import Foundation
@testable import MapboxNavigation

class TestImageDownloadOperation: Operation, ImageDownload {

    private static var operations: [URL: TestImageDownloadOperation] = [:]

    private(set) var request: URLRequest?
    weak private var session: URLSession?

    private var completionBlocks: Array<ImageDownloadCompletionBlock> = []

    required init(request: URLRequest, in session: URLSession) {
        self.request = request
        self.session = session

        super.init()

        TestImageDownloadOperation.operations[request.url!] = self
    }

    static func reset() {
        operations.removeAll()
    }

    static func operationForURL(_ URL: URL) -> TestImageDownloadOperation? {
        return operations[URL]
    }

    func addCompletion(_ completion: @escaping ImageDownloadCompletionBlock) {
        let wrappedCompletion = { (image: UIImage?, data: Data?, error: Error?) in
            completion(image, data, error)
            // Sadly we need to tick the run loop here to deal with the fact that the underlying implementations hop between queues. This has a similar effect to using XCTestCase's async expectations.
            RunLoop.current.run(until: Date())
        }
        self.completionBlocks.append(wrappedCompletion)
    }

    func shouldDecompressImages() -> Bool {
        return false
    }

    func setShouldDecompressImages(_ value: Bool) {
    }

    func credential() -> URLCredential? {
        fatalError("credential() has not been implemented")
    }

    func setCredential(_ value: URLCredential?) {
    }

    func fireAllCompletions(_ image: UIImage, data: Data?, error: Error?) {
        completionBlocks.forEach { completion in
            completion(image, data, error)
        }
    }
}
