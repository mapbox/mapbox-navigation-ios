import Foundation
import MapboxNavigationNative

extension NavigationStatus {
    /// Legacy `roadName` property that returns first road name based on the `roads` array.
    var roadName: String {
        roads.map({ $0.text }).prefix(while: { $0 != "/" }).joined(separator: " ")
    }
}
