import Foundation

extension Notification.Name {
    /**
     Emitted when something changed in the `NavigationSettings`.
     */
    public static let navigationSettingsDidChange = Notification.Name(MBNavigationSettingsDidChange)
}

/**
 `NavigationSettings` provides a wrapper for UserDefaults.
 
 Properties are prefixed and before they are stored in UserDefaults.standard.
 */
@objc(MBNavigationSettings)
public class NavigationSettings: NSObject {
    
    /**
     The volume that the voice controller will use.
     
     This volume is relative to the system’s volume where 1.0 is same volume as the system.
    */
    @objc public dynamic var voiceVolume: Float     = 1.0
    
    /**
     Indicates whether the voice controller should be muted or not.
     */
    @objc public dynamic var voiceMuted: Bool      = false
    
    public static let shared = NavigationSettings()
    
    /// Returns a reflection of this class excluding the `properties` variable.
    lazy var properties: [Mirror.Child] = {
        let properties = Mirror(reflecting: self).children
        return properties.filter({ (child) -> Bool in
            if let label = child.label {
                return label != "properties.storage"
            }
            return false
        })
    }()
    
    override init() {
        super.init()
        for property in properties {
            guard let key = property.label else { continue }
            let val = UserDefaults.standard.object(forKey: key.prefixed) ?? value(forKey: key)
            setValue(val, forKey: key)
            addObserver(self, forKeyPath: key, options: .new, context: nil)
        }
    }
    
    deinit {
        for property in properties {
            guard let key = property.label else { continue }
            removeObserver(self, forKeyPath: key)
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        var found = false
        
        for property in properties {
            guard let key = property.label else { continue }
            
            if key == keyPath {
                guard let val = change?[.newKey] else { continue }
                
                UserDefaults.standard.set(val, forKey: key.prefixed)
                NotificationCenter.default.post(name: .navigationSettingsDidChange, object: nil, userInfo: [key: val])
                
                found = true
                break
            }
        }
        
        if !found {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

extension String {
    fileprivate var prefixed: String {
        return "MB" + self
    }
}
