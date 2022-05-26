import UIKit

// :nodoc:
@available(*, deprecated, message: "This class is no longer used.")
@objc(MBReportButton)
public class ReportButton: Button {
    
    static let defaultInsets: UIEdgeInsets = 10.0
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    private func commonInit() {
        contentEdgeInsets = ReportButton.defaultInsets
        layer.cornerRadius = Style.defaultCornerRadius
    }
}
