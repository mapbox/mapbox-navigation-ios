import UIKit

class PreviewDayStyle: DayStyle {
    
    required init() {
        super.init()
    }

    override func apply() {
        super.apply()
        
        WayNameView.appearance().backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        WayNameView.appearance().borderColor = #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1)
        WayNameView.appearance().borderWidth = 2.0
        
        WayNameLabel.appearance().textAlignment = .center
        WayNameLabel.appearance().normalFont = UIFont.systemFont(ofSize: 18.0, weight: .regular).adjustedFont
        WayNameLabel.appearance().normalTextColor = #colorLiteral(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        
        UserPuckCourseView.appearance().puckColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
    }
}
