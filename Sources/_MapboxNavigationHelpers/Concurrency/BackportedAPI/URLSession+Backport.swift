import Foundation

extension URLSessionTask: CancellableAsyncStateValue {}

@available(iOS, deprecated: 15.0, message: "Use iOS 15 API instead.")
extension URLSession {
    public func data(from url: URL) async throws -> (data: Data, response: URLResponse) {
        try await data(for: URLRequest(url: url))
    }

    public func data(for request: URLRequest) async throws -> (data: Data, response: URLResponse) {
        let state: CancellableAsyncState<URLSessionTask> = .init()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let dataTask = self.dataTask(with: request) { data, response, error in
                    guard let data, let response else {
                        let error = error ?? URLError(.badServerResponse)
                        return continuation.resume(throwing: error)
                    }

                    continuation.resume(returning: (data, response))
                }
                dataTask.resume()
                state.activate(with: dataTask)
            }
        } onCancel: {
            state.cancel()
        }
    }

    public func download(with request: URLRequest) async throws -> (cacheUrl: URL, response: URLResponse) {
        let state: CancellableAsyncState<URLSessionTask> = .init()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let dataTask = self.downloadTask(with: request) { url, response, error in
                    guard let url, let response else {
                        let error = error ?? URLError(.badServerResponse)
                        return continuation.resume(throwing: error)
                    }
                    // We need to move file, because it will be removed when this function ends.
                    let temporaryUrl = FileManager.default
                        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(url.lastPathComponent)
                    do {
                        try FileManager.default.moveItem(at: url, to: temporaryUrl)
                        continuation.resume(returning: (temporaryUrl, response))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                dataTask.resume()
                state.activate(with: dataTask)
            }
        } onCancel: {
            state.cancel()
        }
    }
}
