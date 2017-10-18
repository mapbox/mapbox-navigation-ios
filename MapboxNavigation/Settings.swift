import Foundation


let NavigationSettingsDidChange = Notification.Name("MBNavigationSettingsDidChange")

@objc class NavigationSettings: NSObject {
    
    var defaults: UserDefaults!
    
    @objc public dynamic var voiceVolume    : Float     = 1.0
    @objc public dynamic var voiceMuted     : Bool      = false
    
    @objc static let shared = NavigationSettings()
    
    override init() {
        self.defaults = UserDefaults(suiteName: "com.mapbox.MapboxNavigation")!
        super.init()
        
        let properties = Mirror(reflecting: self).children
        for property in properties {
            guard let key = property.label else { continue }
            
            let val = defaults.object(forKey: key) ?? value(forKey: key)
            setValue(val, forKey: key)
            addObserver(self, forKeyPath: key, options: .new, context: nil)
        }
    }
    
    deinit {
        let properties = Mirror(reflecting: self).children
        for property in properties {
            guard let key = property.label else { continue }
            
            removeObserver(self, forKeyPath: key)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        var found = false
        
        let properties = Mirror(reflecting: self).children
        for property in properties {
            guard let key = property.label else { continue }
            
            if key == keyPath {
                guard let val = change?[.newKey] else { continue }
                
                defaults.set(val, forKey: key)
                NotificationCenter.default.post(name: NavigationSettingsDidChange, object: nil, userInfo: [key: val])
                
                found = true
                break
            }
        }
        
        if found == false {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

