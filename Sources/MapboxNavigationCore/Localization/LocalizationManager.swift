import _MapboxNavigationHelpers
import Foundation

// swiftformat:disable enumNamespaces
/// This class handles the localization of the string inside of the SDK.
public struct LocalizationManager {
    /// Set this bundle if you want to provide a custom localization for some string in the SDK. If the provided bundle
    /// does not contain the localized version, the string from the default bundle inside the SDK will be used.
    public static var customLocalizationBundle: Bundle? {
        get { _customLocalizationBundle.read() }
        set { _customLocalizationBundle.update(newValue) }
    }

    private static let _customLocalizationBundle: NSLocked<Bundle?> = .init(nil)
    private static let nonExistentKeyValue = "_nonexistent_key_value_".uppercased()

    /// Retrieves the localized string for a given key.
    /// - Parameters:
    ///   - key: The key for the string to localize.
    ///   - tableName: The name of the table containing the localized string  identified by `key`.
    ///   - defaultBundle: The default bundle containing the table's strings file.
    ///   - value: The value to use if the key is not found (optional).
    ///   - comment: A note to the translator describing the context where the localized string is presented to the
    /// user.
    /// - Returns: A localized string.
    public static func localizedString(
        _ key: String,
        tableName: String? = nil,
        defaultBundle: Bundle,
        value: String,
        comment: String = ""
    ) -> String {
        if let customBundle = customLocalizationBundle {
            let customString = NSLocalizedString(
                key,
                tableName: tableName,
                bundle: customBundle,
                value: nonExistentKeyValue,
                comment: comment
            )
            if customString != nonExistentKeyValue {
                return customString
            }
        }

        return NSLocalizedString(key, tableName: tableName, bundle: defaultBundle, value: value, comment: comment)
    }
}
