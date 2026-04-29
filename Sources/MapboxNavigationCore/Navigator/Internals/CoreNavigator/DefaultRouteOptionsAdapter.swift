import Foundation
import MapboxNavigationNative_Private

final class DefaultRouteOptionsAdapter: RouteOptionsAdapter {
    typealias Adapter = (String) -> String

    let adapter: Adapter

    init(adapter: @escaping Adapter) {
        self.adapter = adapter
    }

    func modifyRouteRequestOptions(forUrl url: String) -> String {
        adapter(url)
    }
}
