import UIKit

@IBDesignable
class DashedLineView: UIView {

    @IBInspectable var dashedLength: CGFloat = 4 { didSet { updateProperties() } }
    @IBInspectable var dashedGap: CGFloat = 4 { didSet { updateProperties() } }
    @IBInspectable var lineColor: UIColor = NavigationUI.shared.lineColor { didSet { updateProperties() } }

    let dashedLineLayer = CAShapeLayer()

    override func layoutSubviews() {
        if dashedLineLayer.superlayer == nil {
            layer.addSublayer(dashedLineLayer)
        }
        updateProperties()
    }

    func updateProperties() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height/2))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height/2))
        dashedLineLayer.path = path.cgPath

        dashedLineLayer.frame = bounds
        dashedLineLayer.fillColor = UIColor.clear.cgColor
        dashedLineLayer.strokeColor = lineColor.cgColor
        dashedLineLayer.lineWidth = bounds.height
        dashedLineLayer.lineDashPattern = [dashedLength as NSNumber, dashedGap as NSNumber]
    }
}
