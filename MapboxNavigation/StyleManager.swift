import UIKit
import Solar

protocol StyleManagerDelegate: class {
    func locationFor(styleManager: StyleManager) -> CLLocation
    func styleManager(_ styleManager: StyleManager, didApply style: Style)
    func styleManagerDidRefreshAppearance(_ styleManager: StyleManager)
}

class StyleManager {
    
    weak var delegate: StyleManagerDelegate!
    
    var currentStyleType: StyleType?
    var styles = [Style]() { didSet { applyStyle() } }
    var automaticallyAdjustsStyleForTimeOfDay = true {
        didSet {
            // TODO: If true, fire notification when time of day changes
            // TODO: If false, cancel ongoing notifications
        }
    }
    
    required init(_ delegate: StyleManagerDelegate) {
        self.delegate = delegate
    }
    
    func applyStyle() {
        let location = delegate.locationFor(styleManager: self)
        let styleTypeForTimeOfDay = styleType(for: location)
        
        for style in styles {
            if style.styleType == styleTypeForTimeOfDay {
                style.apply()
                currentStyleType = style.styleType
                delegate.styleManager(self, didApply: style)
            }
        }
    }
    
    func styleType(for location: CLLocation) -> StyleType {
        guard let solar = Solar(coordinate: location.coordinate),
            let sunrise = solar.sunrise,
            let sunset = solar.sunset else {
                return .dayStyle
        }
        
        return solar.date.isNighttime(sunrise: sunrise, sunset: sunset) ? .nightStyle : .dayStyle
    }
    
    func forceRefreshAppearanceIfNeeded() {
        let location = delegate.locationFor(styleManager: self)
        
        guard currentStyleType != styleType(for: location) else {
            return
        }
        
        applyStyle()
        
        for window in UIApplication.shared.windows {
            for view in window.subviews {
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
        
        delegate.styleManagerDidRefreshAppearance(self)
    }
}

extension Date {
    fileprivate func isNighttime(sunrise: Date, sunset: Date) -> Bool {
        let calendar = Calendar.current
        let currentMinutesFromMidnight = calendar.component(.hour, from: self) * 60 + calendar.component(.minute, from: self)
        let sunriseMinutesFromMidnight = calendar.component(.hour, from: sunrise) * 60 + calendar.component(.minute, from: sunrise)
        let sunsetMinutesFromMidnight = calendar.component(.hour, from: sunset) * 60 + calendar.component(.minute, from: sunset)
        return currentMinutesFromMidnight < sunriseMinutesFromMidnight || currentMinutesFromMidnight > sunsetMinutesFromMidnight
    }
}
