import Foundation
@testable import MapboxNavigation

/**
 * This class can be used as a replacement for the `ImageDownloader`'s default download operation class, for spying on url download requests as well as returning canned responses ad hoc.
 */
class ImageDownloadOperationSpy: Operation, ImageDownload {

    private static var operations: [URL: ImageDownloadOperationSpy] = [:]

    private(set) var request: URLRequest?
    weak private var session: URLSession?

    private var completionBlocks: Array<ImageDownloadCompletionBlock> = []

    required init(request: URLRequest, in session: URLSession) {
        self.request = request
        self.session = session

        super.init()

        ImageDownloadOperationSpy.operations[request.url!] = self
    }

    static func reset() {
        operations.removeAll()
    }

    /**
     * Retrieve an operation spy instance for the given URL, which can then be used to inspect and/or execute completion handlers
     */
    static func operationForURL(_ URL: URL) -> ImageDownloadOperationSpy? {
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
