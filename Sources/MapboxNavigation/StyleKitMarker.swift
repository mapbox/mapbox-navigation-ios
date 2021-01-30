import UIKit

public class StyleKitMarker: NSObject {

    //// Drawing Methods

    @objc dynamic public class func drawMarker(frame: CGRect = CGRect(x: 57, y: 27, width: 50, height: 50), innerColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000), shadowColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), pinColor: UIColor = UIColor(red: 0.290, green: 0.565, blue: 0.886, alpha: 1.000), strokeColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!

        //// Group
        //// Oval 2 Drawing
        context.saveGState()
        context.setAlpha(0.1)

        let oval2Path = UIBezierPath(ovalIn: CGRect(x: 10, y: 40.61, width: 19, height: 8))
        shadowColor.setFill()
        oval2Path.fill()

        context.restoreGState()

        //// Group 2
        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 18.04, y: 43.43))
        bezier2Path.addCurve(to: CGPoint(x: 20.96, y: 43.43), controlPoint1: CGPoint(x: 18.85, y: 44.18), controlPoint2: CGPoint(x: 20.16, y: 44.17))
        bezier2Path.addCurve(to: CGPoint(x: 37, y: 19.55), controlPoint1: CGPoint(x: 20.96, y: 43.43), controlPoint2: CGPoint(x: 37, y: 29.24))
        bezier2Path.addCurve(to: CGPoint(x: 19.5, y: 2), controlPoint1: CGPoint(x: 37, y: 9.86), controlPoint2: CGPoint(x: 29.16, y: 2))
        bezier2Path.addCurve(to: CGPoint(x: 2, y: 19.55), controlPoint1: CGPoint(x: 9.84, y: 2), controlPoint2: CGPoint(x: 2, y: 9.86))
        bezier2Path.addCurve(to: CGPoint(x: 18.04, y: 43.43), controlPoint1: CGPoint(x: 2, y: 29.24), controlPoint2: CGPoint(x: 18.04, y: 43.43))
        bezier2Path.close()
        bezier2Path.usesEvenOddFillRule = true
        pinColor.setFill()
        bezier2Path.fill()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 18.04, y: 43.43))
        bezier3Path.addCurve(to: CGPoint(x: 20.96, y: 43.43), controlPoint1: CGPoint(x: 18.85, y: 44.18), controlPoint2: CGPoint(x: 20.16, y: 44.17))
        bezier3Path.addCurve(to: CGPoint(x: 37, y: 19.55), controlPoint1: CGPoint(x: 20.96, y: 43.43), controlPoint2: CGPoint(x: 37, y: 29.24))
        bezier3Path.addCurve(to: CGPoint(x: 19.5, y: 2), controlPoint1: CGPoint(x: 37, y: 9.86), controlPoint2: CGPoint(x: 29.16, y: 2))
        bezier3Path.addCurve(to: CGPoint(x: 2, y: 19.55), controlPoint1: CGPoint(x: 9.84, y: 2), controlPoint2: CGPoint(x: 2, y: 9.86))
        bezier3Path.addCurve(to: CGPoint(x: 18.04, y: 43.43), controlPoint1: CGPoint(x: 2, y: 29.24), controlPoint2: CGPoint(x: 18.04, y: 43.43))
        bezier3Path.close()
        strokeColor.setStroke()
        bezier3Path.lineWidth = 3
        bezier3Path.stroke()

        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 12.5, y: 12.16, width: 14, height: 14))
        innerColor.setFill()
        ovalPath.fill()
    }

}
