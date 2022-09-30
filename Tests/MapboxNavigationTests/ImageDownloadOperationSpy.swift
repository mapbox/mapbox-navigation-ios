import Foundation
import UIKit
@testable import MapboxNavigation

/**
 * This class can be used as a replacement for the `ImageDownloader`'s default download operation class, for spying on url download requests as well as returning canned responses ad hoc.
 */
class ImageDownloadOperationSpy: Operation, ImageDownload {
    private static var operations: [URL: ImageDownloadOperationSpy] = [:]

    private(set) var request: URLRequest?
    weak private var session: URLSession?

    private var completionBlocks: Array<CachedResponseCompletionHandler> = []

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

    func addCompletion(_ completion: @escaping CachedResponseCompletionHandler) {
        let wrappedCompletion = { (cachedResponse: CachedURLResponse?, error: Error?) in
            completion(cachedResponse, error)
            // Sadly we need to tick the run loop here to deal with the fact that the underlying implementations hop between queues. This has a similar effect to using XCTestCase's async expectations.
            RunLoop.current.run(until: Date())
        }
        self.completionBlocks.append(wrappedCompletion)
    }

    func fireAllCompletions(_ cachedResponse: CachedURLResponse?, error: Error?) {
        completionBlocks.forEach { completion in
            completion(cachedResponse, error)
        }
    }
}
