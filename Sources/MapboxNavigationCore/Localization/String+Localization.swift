import _MapboxNavigationLocalization
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

    func localizedValue(prefix: String) -> String {
        localizedKeyValue(prefix: prefix).localizedString(value: self)
    }

    private func localizedKeyValue(prefix: String) -> String {
        let value = replacingOccurrences(of: " ", with: "_")
        return "\(prefix)\(value)".uppercased()
    }
}
