import UIKit

class PreviewNightStyle: NightStyle {
    
    required init() {
        super.init()
    }
    
    override func apply() {
        super.apply()
        
        BottomBannerView.appearance().backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        BottomPaddingView.appearance().backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        
        WayNameView.appearance().backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        WayNameView.appearance().borderColor = #colorLiteral(red: 0.368, green: 0.368, blue: 0.368, alpha: 1)
        WayNameView.appearance().borderWidth = 2.0
        
        WayNameLabel.appearance().textAlignment = .center
        WayNameLabel.appearance().normalFont = UIFont.systemFont(ofSize: 18.0, weight: .regular).adjustedFont
        WayNameLabel.appearance().normalTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        UserPuckCourseView.appearance().puckColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        
        CameraFloatingButton.appearance().backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        CameraFloatingButton.appearance().borderColor = #colorLiteral(red: 0.368, green: 0.368, blue: 0.368, alpha: 1)
        CameraFloatingButton.appearance().borderWidth = 2.0
        CameraFloatingButton.appearance().cornerRadius = 10.0
        
        BackButton.appearance().backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        BackButton.appearance().borderColor = #colorLiteral(red: 0.368, green: 0.368, blue: 0.368, alpha: 1)
        BackButton.appearance().borderWidth = 2.0
        BackButton.appearance().cornerRadius = 10.0
        BackButton.appearance().textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        BackButton.appearance().tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        BackButton.appearance().textFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        
        PreviewButton.appearance().borderWidth = 2.0
        PreviewButton.appearance().cornerRadius = 5.0
        PreviewButton.appearance().borderColor = #colorLiteral(red: 0.368, green: 0.368, blue: 0.368, alpha: 1)
        PreviewButton.appearance().tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        PreviewButton.appearance().backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        
        StartButton.appearance().backgroundColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        StartButton.appearance().cornerRadius = 5.0
        StartButton.appearance().tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    }
}
