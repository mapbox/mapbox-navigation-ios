import Foundation

extension String {
    var nonEmptyString: String? {
        return !isEmpty ? self : nil
    }
}
