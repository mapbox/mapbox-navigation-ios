import Foundation
import MapboxNavigationCore

extension String {
    func localizedString(
        value: String,
        tableName: String? = nil,
        defaultBundle: Bundle = .mapboxNavigation,
        comment: String = ""
    ) -> String {
        LocalizationManager.localizedString(
            self,
            tableName: tableName,
            defaultBundle: defaultBundle,
            value: value,
            comment: comment
        )
    }
}
