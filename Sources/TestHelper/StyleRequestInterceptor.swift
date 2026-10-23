import MapboxCommon
import MapboxMaps

/// Serves a valid empty style for every Mapbox style request, so a test can set a real
/// `mapbox://` style URI without reaching the network.
///
/// This covers the case ``TestCase/resolveDefaultStylesOffline()`` deliberately cannot:
/// that one swaps the style for a JSON-backed one, which makes `MapboxMap.styleURI` read
/// back `nil`. A test that sets a style *and then asserts on its URI* needs the URI to
/// survive, so only the bytes can be replaced — which is what an interceptor does.
final class StyleRequestInterceptor: HttpServiceInterceptorInterface {
    private static let emptyStyle = Data(#"{"version":8,"name":"empty","sources":{},"layers":[]}"#.utf8)

    func onRequest(
        for request: HttpRequest,
        continuation: @escaping HttpServiceInterceptorRequestContinuation
    ) {
        guard request.url.contains("/styles/v1/") else {
            continuation(HttpRequestOrResponse.fromHttpRequest(request))
            return
        }

        let data = HttpResponseData(headers: [:], code: 200, data: Self.emptyStyle)
        let response = HttpResponse(identifier: 0, request: request, result: .success(data))
        continuation(HttpRequestOrResponse.fromHttpResponse(response))
    }

    func onResponse(
        for response: HttpResponse,
        continuation: @escaping HttpServiceInterceptorResponseContinuation
    ) {
        continuation(response)
    }
}
