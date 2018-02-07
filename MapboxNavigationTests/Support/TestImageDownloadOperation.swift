import Foundation
import SDWebImage

class TestImageDownloadOperation: Operation, SDWebImageDownloaderOperationInterface {

    private static var operations: [URL : TestImageDownloadOperation] = [:]

    private(set) var request: URLRequest?
    weak private var session: URLSession?
    private(set) var options: SDWebImageDownloaderOptions

    private(set) var progressBlock: SDWebImageDownloaderProgressBlock?
    private(set) var completedBlock: SDWebImageDownloaderCompletedBlock?

    required init(request: URLRequest?, in session: URLSession?, options: SDWebImageDownloaderOptions) {
        self.request = request
        self.session = session
        self.options = options

        super.init()

        TestImageDownloadOperation.operations[request!.url!] = self
    }

    static func reset() {
        operations.removeAll()
    }

    static func operationForURL(_ URL: URL) -> TestImageDownloadOperation? {
        return operations[URL]
    }

    func addHandlers(forProgress progressBlock: SDWebImageDownloaderProgressBlock?, completed completedBlock: SDWebImageDownloaderCompletedBlock?) -> Any? {
        self.progressBlock = progressBlock
        if let completedBlock = completedBlock {
            self.completedBlock = { (image: UIImage?, data: Data?, error: Error?, success: Bool) in
                completedBlock(image, data, error, success)
                // Sadly we need to tick the run loop here to deal with the fact that the underlying implementations hop between queues. This has a similar effect to using XCTestCase's async expectations.
                RunLoop.current.run(until: Date())
            }
        }

        return nil
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
}
