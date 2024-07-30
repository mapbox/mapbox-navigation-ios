import Foundation

extension String {
    func localizedString(
        value: String,
        tableName: String? = nil,
        defaultBundle: Bundle = .mapboxNavigationUXCore,
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
