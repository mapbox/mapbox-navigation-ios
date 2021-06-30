import Foundation
@_implementationOnly import MapboxCommon_Private

enum NavigationBillingMethod: String {
    case user = "user"
    case request = "request"
    
    static let allValues: [Self] = [.user, .request]
}

@objc(MBXAccounts)
public class Accounts: NSObject {
    @objc public static var serviceSkuToken: String? {
        var billingMethodValue = Bundle.main.object(forInfoDictionaryKey: "MBXNavigationBillingMethod") as? String
        if billingMethodValue == "" {
            billingMethodValue = nil
        }
        
        switch NavigationBillingMethod(rawValue: billingMethodValue ?? NavigationBillingMethod.user.rawValue) {
        case .user:
            return TokenGenerator.getSKUToken(for: .navigationMAUS)
        case .request:
            return nil
        case .none:
            preconditionFailure("Unrecognized billing method \(String(describing: billingMethodValue)). Valid billing methods are: \(NavigationBillingMethod.allValues.map { $0.rawValue }).")
        }
    }
}
