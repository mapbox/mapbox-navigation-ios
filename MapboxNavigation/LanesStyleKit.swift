import UIKit

@objc(MBLanesStyleKit)
public class LanesStyleKit: NSObject {

    //// Drawing Methods

    @objc dynamic public class func drawLane_straight_right(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: 9, y: 11.5, width: 4, height: 15.5))
        primaryColor.setFill()
        rectanglePath.fill()

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 11.02, y: 2))
        bezierPath.addCurve(to: CGPoint(x: 16.86, y: 10.13), controlPoint1: CGPoint(x: 11.06, y: 2.06), controlPoint2: CGPoint(x: 16.74, y: 9.97))
        bezierPath.addCurve(to: CGPoint(x: 17.02, y: 10.52), controlPoint1: CGPoint(x: 16.96, y: 10.23), controlPoint2: CGPoint(x: 17.02, y: 10.37))
        bezierPath.addCurve(to: CGPoint(x: 16.5, y: 11.03), controlPoint1: CGPoint(x: 17.02, y: 10.8), controlPoint2: CGPoint(x: 16.79, y: 11.03))
        bezierPath.addCurve(to: CGPoint(x: 16.31, y: 10.99), controlPoint1: CGPoint(x: 16.44, y: 11.03), controlPoint2: CGPoint(x: 16.37, y: 11.02))
        bezierPath.addCurve(to: CGPoint(x: 13.59, y: 10), controlPoint1: CGPoint(x: 16.2, y: 10.95), controlPoint2: CGPoint(x: 13.69, y: 10.04))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 10.52), controlPoint1: CGPoint(x: 13.2, y: 10), controlPoint2: CGPoint(x: 13.01, y: 10.23))
        bezierPath.addCurve(to: CGPoint(x: 13, y: 10.72), controlPoint1: CGPoint(x: 13.01, y: 10.59), controlPoint2: CGPoint(x: 13, y: 10.66))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 11.99), controlPoint1: CGPoint(x: 13, y: 10.8), controlPoint2: CGPoint(x: 13.01, y: 11.99))
        bezierPath.addLine(to: CGPoint(x: 9.01, y: 11.92))
        bezierPath.addCurve(to: CGPoint(x: 9.02, y: 10.66), controlPoint1: CGPoint(x: 9.01, y: 11.92), controlPoint2: CGPoint(x: 9.02, y: 10.75))
        bezierPath.addCurve(to: CGPoint(x: 9.01, y: 10.46), controlPoint1: CGPoint(x: 9.01, y: 10.6), controlPoint2: CGPoint(x: 9.01, y: 10.53))
        bezierPath.addCurve(to: CGPoint(x: 8.53, y: 9.94), controlPoint1: CGPoint(x: 9.01, y: 10.17), controlPoint2: CGPoint(x: 8.82, y: 9.94))
        bezierPath.addCurve(to: CGPoint(x: 5.71, y: 10.93), controlPoint1: CGPoint(x: 8.32, y: 9.98), controlPoint2: CGPoint(x: 5.82, y: 10.89))
        bezierPath.addCurve(to: CGPoint(x: 5.52, y: 10.97), controlPoint1: CGPoint(x: 5.65, y: 10.96), controlPoint2: CGPoint(x: 5.58, y: 10.97))
        bezierPath.addCurve(to: CGPoint(x: 5, y: 10.46), controlPoint1: CGPoint(x: 5.23, y: 10.97), controlPoint2: CGPoint(x: 5, y: 10.74))
        bezierPath.addCurve(to: CGPoint(x: 5.16, y: 10.08), controlPoint1: CGPoint(x: 5, y: 10.3), controlPoint2: CGPoint(x: 5.06, y: 10.17))
        bezierPath.addCurve(to: CGPoint(x: 11.01, y: 2), controlPoint1: CGPoint(x: 5.28, y: 9.9), controlPoint2: CGPoint(x: 10.97, y: 2.06))
        bezierPath.addLine(to: CGPoint(x: 11.02, y: 2))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 18.05, y: 14.59))
        bezier2Path.addLine(to: CGPoint(x: 19.31, y: 14.59))
        bezier2Path.addLine(to: CGPoint(x: 19.31, y: 14.59))
        bezier2Path.addCurve(to: CGPoint(x: 19.51, y: 14.59), controlPoint1: CGPoint(x: 19.37, y: 14.59), controlPoint2: CGPoint(x: 19.44, y: 14.59))
        bezier2Path.addCurve(to: CGPoint(x: 20.03, y: 14.1), controlPoint1: CGPoint(x: 19.8, y: 14.59), controlPoint2: CGPoint(x: 20.03, y: 14.4))
        bezier2Path.addCurve(to: CGPoint(x: 20.03, y: 14.01), controlPoint1: CGPoint(x: 20.03, y: 14.07), controlPoint2: CGPoint(x: 20.03, y: 14.04))
        bezier2Path.addLine(to: CGPoint(x: 20.03, y: 14.01))
        bezier2Path.addLine(to: CGPoint(x: 19.04, y: 11.28))
        bezier2Path.addLine(to: CGPoint(x: 19.04, y: 11.29))
        bezier2Path.addCurve(to: CGPoint(x: 19, y: 11.09), controlPoint1: CGPoint(x: 19.02, y: 11.23), controlPoint2: CGPoint(x: 19, y: 11.16))
        bezier2Path.addCurve(to: CGPoint(x: 19.52, y: 10.58), controlPoint1: CGPoint(x: 19, y: 10.81), controlPoint2: CGPoint(x: 19.23, y: 10.58))
        bezier2Path.addCurve(to: CGPoint(x: 19.9, y: 10.74), controlPoint1: CGPoint(x: 19.67, y: 10.58), controlPoint2: CGPoint(x: 19.8, y: 10.64))
        bezier2Path.addLine(to: CGPoint(x: 19.9, y: 10.74))
        bezier2Path.addLine(to: CGPoint(x: 26.97, y: 16.59))
        bezier2Path.addLine(to: CGPoint(x: 19.83, y: 22.44))
        bezier2Path.addLine(to: CGPoint(x: 19.84, y: 22.43))
        bezier2Path.addCurve(to: CGPoint(x: 19.46, y: 22.6), controlPoint1: CGPoint(x: 19.74, y: 22.53), controlPoint2: CGPoint(x: 19.6, y: 22.6))
        bezier2Path.addCurve(to: CGPoint(x: 18.94, y: 22.08), controlPoint1: CGPoint(x: 19.17, y: 22.6), controlPoint2: CGPoint(x: 18.94, y: 22.37))
        bezier2Path.addCurve(to: CGPoint(x: 18.98, y: 21.89), controlPoint1: CGPoint(x: 18.94, y: 22.01), controlPoint2: CGPoint(x: 18.95, y: 21.95))
        bezier2Path.addLine(to: CGPoint(x: 18.98, y: 21.89))
        bezier2Path.addLine(to: CGPoint(x: 19.97, y: 19.16))
        bezier2Path.addLine(to: CGPoint(x: 19.97, y: 19.16))
        bezier2Path.addCurve(to: CGPoint(x: 19.97, y: 19.07), controlPoint1: CGPoint(x: 19.97, y: 19.14), controlPoint2: CGPoint(x: 19.97, y: 19.1))
        bezier2Path.addCurve(to: CGPoint(x: 19.45, y: 18.59), controlPoint1: CGPoint(x: 19.97, y: 18.78), controlPoint2: CGPoint(x: 19.74, y: 18.59))
        bezier2Path.addCurve(to: CGPoint(x: 19.25, y: 18.58), controlPoint1: CGPoint(x: 19.38, y: 18.59), controlPoint2: CGPoint(x: 19.31, y: 18.58))
        bezier2Path.addLine(to: CGPoint(x: 19.25, y: 18.58))
        bezier2Path.addLine(to: CGPoint(x: 17.99, y: 18.59))
        bezier2Path.usesEvenOddFillRule = true
        primaryColor.setFill()
        bezier2Path.fill()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 11.03, y: 27))
        bezier3Path.addLine(to: CGPoint(x: 11.03, y: 22.87))
        bezier3Path.addCurve(to: CGPoint(x: 13, y: 18.61), controlPoint1: CGPoint(x: 11.03, y: 21.23), controlPoint2: CGPoint(x: 11.73, y: 19.65))
        bezier3Path.addCurve(to: CGPoint(x: 17.84, y: 16.61), controlPoint1: CGPoint(x: 14.23, y: 17.61), controlPoint2: CGPoint(x: 15.93, y: 16.61))
        bezier3Path.addLine(to: CGPoint(x: 20.03, y: 16.61))
        primaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.stroke()
    }

    @objc dynamic public class func drawLane_straight_only(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), secondaryColor: UIColor = UIColor(red: 0.618, green: 0.618, blue: 0.618, alpha: 1.000)) {

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 18.05, y: 14.59))
        bezier2Path.addLine(to: CGPoint(x: 19.31, y: 14.59))
        bezier2Path.addLine(to: CGPoint(x: 19.31, y: 14.59))
        bezier2Path.addCurve(to: CGPoint(x: 19.51, y: 14.59), controlPoint1: CGPoint(x: 19.37, y: 14.59), controlPoint2: CGPoint(x: 19.44, y: 14.59))
        bezier2Path.addCurve(to: CGPoint(x: 20.03, y: 14.1), controlPoint1: CGPoint(x: 19.8, y: 14.59), controlPoint2: CGPoint(x: 20.03, y: 14.4))
        bezier2Path.addCurve(to: CGPoint(x: 20.03, y: 14.01), controlPoint1: CGPoint(x: 20.03, y: 14.07), controlPoint2: CGPoint(x: 20.03, y: 14.04))
        bezier2Path.addLine(to: CGPoint(x: 20.03, y: 14.01))
        bezier2Path.addLine(to: CGPoint(x: 19.04, y: 11.28))
        bezier2Path.addLine(to: CGPoint(x: 19.04, y: 11.29))
        bezier2Path.addCurve(to: CGPoint(x: 19, y: 11.09), controlPoint1: CGPoint(x: 19.02, y: 11.23), controlPoint2: CGPoint(x: 19, y: 11.16))
        bezier2Path.addCurve(to: CGPoint(x: 19.52, y: 10.58), controlPoint1: CGPoint(x: 19, y: 10.81), controlPoint2: CGPoint(x: 19.23, y: 10.58))
        bezier2Path.addCurve(to: CGPoint(x: 19.9, y: 10.74), controlPoint1: CGPoint(x: 19.67, y: 10.58), controlPoint2: CGPoint(x: 19.8, y: 10.64))
        bezier2Path.addLine(to: CGPoint(x: 19.9, y: 10.74))
        bezier2Path.addLine(to: CGPoint(x: 26.97, y: 16.59))
        bezier2Path.addLine(to: CGPoint(x: 19.83, y: 22.44))
        bezier2Path.addLine(to: CGPoint(x: 19.84, y: 22.43))
        bezier2Path.addCurve(to: CGPoint(x: 19.46, y: 22.6), controlPoint1: CGPoint(x: 19.74, y: 22.53), controlPoint2: CGPoint(x: 19.6, y: 22.6))
        bezier2Path.addCurve(to: CGPoint(x: 18.94, y: 22.08), controlPoint1: CGPoint(x: 19.17, y: 22.6), controlPoint2: CGPoint(x: 18.94, y: 22.37))
        bezier2Path.addCurve(to: CGPoint(x: 18.98, y: 21.89), controlPoint1: CGPoint(x: 18.94, y: 22.01), controlPoint2: CGPoint(x: 18.95, y: 21.95))
        bezier2Path.addLine(to: CGPoint(x: 18.98, y: 21.89))
        bezier2Path.addLine(to: CGPoint(x: 19.97, y: 19.16))
        bezier2Path.addLine(to: CGPoint(x: 19.97, y: 19.16))
        bezier2Path.addCurve(to: CGPoint(x: 19.97, y: 19.07), controlPoint1: CGPoint(x: 19.97, y: 19.14), controlPoint2: CGPoint(x: 19.97, y: 19.1))
        bezier2Path.addCurve(to: CGPoint(x: 19.45, y: 18.59), controlPoint1: CGPoint(x: 19.97, y: 18.78), controlPoint2: CGPoint(x: 19.74, y: 18.59))
        bezier2Path.addCurve(to: CGPoint(x: 19.25, y: 18.58), controlPoint1: CGPoint(x: 19.38, y: 18.59), controlPoint2: CGPoint(x: 19.31, y: 18.58))
        bezier2Path.addLine(to: CGPoint(x: 19.25, y: 18.58))
        bezier2Path.addLine(to: CGPoint(x: 17.99, y: 18.59))
        bezier2Path.usesEvenOddFillRule = true
        secondaryColor.setFill()
        bezier2Path.fill()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 11.03, y: 27))
        bezier3Path.addLine(to: CGPoint(x: 11.03, y: 22.87))
        bezier3Path.addCurve(to: CGPoint(x: 13, y: 18.61), controlPoint1: CGPoint(x: 11.03, y: 21.23), controlPoint2: CGPoint(x: 11.73, y: 19.65))
        bezier3Path.addCurve(to: CGPoint(x: 17.84, y: 16.61), controlPoint1: CGPoint(x: 14.23, y: 17.61), controlPoint2: CGPoint(x: 15.93, y: 16.61))
        bezier3Path.addLine(to: CGPoint(x: 20.03, y: 16.61))
        secondaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.stroke()

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: 9, y: 11, width: 4, height: 16))
        primaryColor.setFill()
        rectanglePath.fill()

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 11.02, y: 2))
        bezierPath.addCurve(to: CGPoint(x: 16.86, y: 10.13), controlPoint1: CGPoint(x: 11.06, y: 2.06), controlPoint2: CGPoint(x: 16.74, y: 9.97))
        bezierPath.addCurve(to: CGPoint(x: 17.02, y: 10.52), controlPoint1: CGPoint(x: 16.96, y: 10.23), controlPoint2: CGPoint(x: 17.02, y: 10.37))
        bezierPath.addCurve(to: CGPoint(x: 16.5, y: 11.03), controlPoint1: CGPoint(x: 17.02, y: 10.8), controlPoint2: CGPoint(x: 16.79, y: 11.03))
        bezierPath.addCurve(to: CGPoint(x: 16.31, y: 10.99), controlPoint1: CGPoint(x: 16.44, y: 11.03), controlPoint2: CGPoint(x: 16.37, y: 11.02))
        bezierPath.addCurve(to: CGPoint(x: 13.59, y: 10), controlPoint1: CGPoint(x: 16.2, y: 10.95), controlPoint2: CGPoint(x: 13.69, y: 10.04))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 10.52), controlPoint1: CGPoint(x: 13.2, y: 10), controlPoint2: CGPoint(x: 13.01, y: 10.23))
        bezierPath.addCurve(to: CGPoint(x: 13, y: 10.72), controlPoint1: CGPoint(x: 13.01, y: 10.59), controlPoint2: CGPoint(x: 13, y: 10.66))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 11.99), controlPoint1: CGPoint(x: 13, y: 10.8), controlPoint2: CGPoint(x: 13.01, y: 11.99))
        bezierPath.addLine(to: CGPoint(x: 9.01, y: 11.92))
        bezierPath.addCurve(to: CGPoint(x: 9.02, y: 10.66), controlPoint1: CGPoint(x: 9.01, y: 11.92), controlPoint2: CGPoint(x: 9.02, y: 10.75))
        bezierPath.addCurve(to: CGPoint(x: 9.01, y: 10.46), controlPoint1: CGPoint(x: 9.01, y: 10.6), controlPoint2: CGPoint(x: 9.01, y: 10.53))
        bezierPath.addCurve(to: CGPoint(x: 8.53, y: 9.94), controlPoint1: CGPoint(x: 9.01, y: 10.17), controlPoint2: CGPoint(x: 8.82, y: 9.94))
        bezierPath.addCurve(to: CGPoint(x: 5.71, y: 10.93), controlPoint1: CGPoint(x: 8.32, y: 9.98), controlPoint2: CGPoint(x: 5.82, y: 10.89))
        bezierPath.addCurve(to: CGPoint(x: 5.52, y: 10.97), controlPoint1: CGPoint(x: 5.65, y: 10.96), controlPoint2: CGPoint(x: 5.58, y: 10.97))
        bezierPath.addCurve(to: CGPoint(x: 5, y: 10.46), controlPoint1: CGPoint(x: 5.23, y: 10.97), controlPoint2: CGPoint(x: 5, y: 10.74))
        bezierPath.addCurve(to: CGPoint(x: 5.16, y: 10.08), controlPoint1: CGPoint(x: 5, y: 10.3), controlPoint2: CGPoint(x: 5.06, y: 10.17))
        bezierPath.addCurve(to: CGPoint(x: 11.01, y: 2), controlPoint1: CGPoint(x: 5.28, y: 9.9), controlPoint2: CGPoint(x: 10.97, y: 2.06))
        bezierPath.addLine(to: CGPoint(x: 11.02, y: 2))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()
    }

    @objc dynamic public class func drawLane_right_h(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 16.46, y: 4))
        bezierPath.addCurve(to: CGPoint(x: 16.77, y: 4.16), controlPoint1: CGPoint(x: 16.55, y: 4), controlPoint2: CGPoint(x: 16.68, y: 4.06))
        bezierPath.addCurve(to: CGPoint(x: 23.85, y: 10.02), controlPoint1: CGPoint(x: 16.93, y: 4.29), controlPoint2: CGPoint(x: 23.85, y: 10.02))
        bezierPath.addCurve(to: CGPoint(x: 16.72, y: 15.86), controlPoint1: CGPoint(x: 23.85, y: 10.02), controlPoint2: CGPoint(x: 16.87, y: 15.73))
        bezierPath.addCurve(to: CGPoint(x: 16.34, y: 16.02), controlPoint1: CGPoint(x: 16.62, y: 15.96), controlPoint2: CGPoint(x: 16.48, y: 16.02))
        bezierPath.addCurve(to: CGPoint(x: 15.82, y: 15.5), controlPoint1: CGPoint(x: 16.05, y: 16.02), controlPoint2: CGPoint(x: 15.82, y: 15.79))
        bezierPath.addCurve(to: CGPoint(x: 15.86, y: 15.31), controlPoint1: CGPoint(x: 15.82, y: 15.44), controlPoint2: CGPoint(x: 15.83, y: 15.37))
        bezierPath.addCurve(to: CGPoint(x: 16.85, y: 12.59), controlPoint1: CGPoint(x: 15.9, y: 15.2), controlPoint2: CGPoint(x: 16.81, y: 12.7))
        bezierPath.addCurve(to: CGPoint(x: 16.33, y: 12.01), controlPoint1: CGPoint(x: 16.85, y: 12.2), controlPoint2: CGPoint(x: 16.62, y: 12.01))
        bezierPath.addCurve(to: CGPoint(x: 16.13, y: 12.01), controlPoint1: CGPoint(x: 16.26, y: 12.01), controlPoint2: CGPoint(x: 16.19, y: 12.01))
        bezierPath.addCurve(to: CGPoint(x: 14.87, y: 12.01), controlPoint1: CGPoint(x: 16.05, y: 12), controlPoint2: CGPoint(x: 14.87, y: 12.01))
        bezierPath.addLine(to: CGPoint(x: 14.93, y: 8.01))
        bezierPath.addCurve(to: CGPoint(x: 16.19, y: 8.02), controlPoint1: CGPoint(x: 14.93, y: 8.01), controlPoint2: CGPoint(x: 16.1, y: 8.02))
        bezierPath.addCurve(to: CGPoint(x: 16.39, y: 8.01), controlPoint1: CGPoint(x: 16.25, y: 8.01), controlPoint2: CGPoint(x: 16.32, y: 8.01))
        bezierPath.addCurve(to: CGPoint(x: 16.91, y: 7.53), controlPoint1: CGPoint(x: 16.68, y: 8.01), controlPoint2: CGPoint(x: 16.91, y: 7.82))
        bezierPath.addCurve(to: CGPoint(x: 15.92, y: 4.71), controlPoint1: CGPoint(x: 16.87, y: 7.32), controlPoint2: CGPoint(x: 15.96, y: 4.82))
        bezierPath.addCurve(to: CGPoint(x: 15.88, y: 4.52), controlPoint1: CGPoint(x: 15.9, y: 4.65), controlPoint2: CGPoint(x: 15.88, y: 4.58))
        bezierPath.addCurve(to: CGPoint(x: 16.39, y: 4), controlPoint1: CGPoint(x: 15.88, y: 4.23), controlPoint2: CGPoint(x: 16.11, y: 4))
        bezierPath.addLine(to: CGPoint(x: 16.46, y: 4))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 9, y: 27))
        bezier2Path.addLine(to: CGPoint(x: 9.06, y: 13.56))
        bezier2Path.addCurve(to: CGPoint(x: 12.94, y: 10.03), controlPoint1: CGPoint(x: 9.06, y: 13.56), controlPoint2: CGPoint(x: 9.34, y: 10.03))
        bezier2Path.addLine(to: CGPoint(x: 20.03, y: 10.03))
        primaryColor.setStroke()
        bezier2Path.lineWidth = 4
        bezier2Path.stroke()
    }

    @objc dynamic public class func drawLane_right_only(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), secondaryColor: UIColor = UIColor(red: 0.618, green: 0.618, blue: 0.618, alpha: 1.000)) {

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: 9, y: 11, width: 4, height: 16))
        secondaryColor.setFill()
        rectanglePath.fill()

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 11.02, y: 2))
        bezierPath.addCurve(to: CGPoint(x: 16.86, y: 10.13), controlPoint1: CGPoint(x: 11.06, y: 2.06), controlPoint2: CGPoint(x: 16.74, y: 9.97))
        bezierPath.addCurve(to: CGPoint(x: 17.02, y: 10.52), controlPoint1: CGPoint(x: 16.96, y: 10.23), controlPoint2: CGPoint(x: 17.02, y: 10.37))
        bezierPath.addCurve(to: CGPoint(x: 16.5, y: 11.03), controlPoint1: CGPoint(x: 17.02, y: 10.8), controlPoint2: CGPoint(x: 16.79, y: 11.03))
        bezierPath.addCurve(to: CGPoint(x: 16.31, y: 10.99), controlPoint1: CGPoint(x: 16.44, y: 11.03), controlPoint2: CGPoint(x: 16.37, y: 11.02))
        bezierPath.addCurve(to: CGPoint(x: 13.59, y: 10), controlPoint1: CGPoint(x: 16.2, y: 10.95), controlPoint2: CGPoint(x: 13.69, y: 10.04))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 10.52), controlPoint1: CGPoint(x: 13.2, y: 10), controlPoint2: CGPoint(x: 13.01, y: 10.23))
        bezierPath.addCurve(to: CGPoint(x: 13, y: 10.72), controlPoint1: CGPoint(x: 13.01, y: 10.59), controlPoint2: CGPoint(x: 13, y: 10.66))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 11.99), controlPoint1: CGPoint(x: 13, y: 10.8), controlPoint2: CGPoint(x: 13.01, y: 11.99))
        bezierPath.addLine(to: CGPoint(x: 9.01, y: 11.92))
        bezierPath.addCurve(to: CGPoint(x: 9.02, y: 10.66), controlPoint1: CGPoint(x: 9.01, y: 11.92), controlPoint2: CGPoint(x: 9.02, y: 10.75))
        bezierPath.addCurve(to: CGPoint(x: 9.01, y: 10.46), controlPoint1: CGPoint(x: 9.01, y: 10.6), controlPoint2: CGPoint(x: 9.01, y: 10.53))
        bezierPath.addCurve(to: CGPoint(x: 8.53, y: 9.94), controlPoint1: CGPoint(x: 9.01, y: 10.17), controlPoint2: CGPoint(x: 8.82, y: 9.94))
        bezierPath.addCurve(to: CGPoint(x: 5.71, y: 10.93), controlPoint1: CGPoint(x: 8.32, y: 9.98), controlPoint2: CGPoint(x: 5.82, y: 10.89))
        bezierPath.addCurve(to: CGPoint(x: 5.52, y: 10.97), controlPoint1: CGPoint(x: 5.65, y: 10.96), controlPoint2: CGPoint(x: 5.58, y: 10.97))
        bezierPath.addCurve(to: CGPoint(x: 5, y: 10.46), controlPoint1: CGPoint(x: 5.23, y: 10.97), controlPoint2: CGPoint(x: 5, y: 10.74))
        bezierPath.addCurve(to: CGPoint(x: 5.16, y: 10.08), controlPoint1: CGPoint(x: 5, y: 10.3), controlPoint2: CGPoint(x: 5.06, y: 10.17))
        bezierPath.addCurve(to: CGPoint(x: 11.01, y: 2), controlPoint1: CGPoint(x: 5.28, y: 9.9), controlPoint2: CGPoint(x: 10.97, y: 2.06))
        bezierPath.addLine(to: CGPoint(x: 11.02, y: 2))
        bezierPath.close()
        secondaryColor.setFill()
        bezierPath.fill()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 18.05, y: 14.59))
        bezier2Path.addLine(to: CGPoint(x: 19.31, y: 14.59))
        bezier2Path.addLine(to: CGPoint(x: 19.31, y: 14.59))
        bezier2Path.addCurve(to: CGPoint(x: 19.51, y: 14.59), controlPoint1: CGPoint(x: 19.37, y: 14.59), controlPoint2: CGPoint(x: 19.44, y: 14.59))
        bezier2Path.addCurve(to: CGPoint(x: 20.03, y: 14.1), controlPoint1: CGPoint(x: 19.8, y: 14.59), controlPoint2: CGPoint(x: 20.03, y: 14.4))
        bezier2Path.addCurve(to: CGPoint(x: 20.03, y: 14.01), controlPoint1: CGPoint(x: 20.03, y: 14.07), controlPoint2: CGPoint(x: 20.03, y: 14.04))
        bezier2Path.addLine(to: CGPoint(x: 20.03, y: 14.01))
        bezier2Path.addLine(to: CGPoint(x: 19.04, y: 11.28))
        bezier2Path.addLine(to: CGPoint(x: 19.04, y: 11.29))
        bezier2Path.addCurve(to: CGPoint(x: 19, y: 11.09), controlPoint1: CGPoint(x: 19.02, y: 11.23), controlPoint2: CGPoint(x: 19, y: 11.16))
        bezier2Path.addCurve(to: CGPoint(x: 19.52, y: 10.58), controlPoint1: CGPoint(x: 19, y: 10.81), controlPoint2: CGPoint(x: 19.23, y: 10.58))
        bezier2Path.addCurve(to: CGPoint(x: 19.9, y: 10.74), controlPoint1: CGPoint(x: 19.67, y: 10.58), controlPoint2: CGPoint(x: 19.8, y: 10.64))
        bezier2Path.addLine(to: CGPoint(x: 19.9, y: 10.74))
        bezier2Path.addLine(to: CGPoint(x: 26.97, y: 16.59))
        bezier2Path.addLine(to: CGPoint(x: 19.83, y: 22.44))
        bezier2Path.addLine(to: CGPoint(x: 19.84, y: 22.43))
        bezier2Path.addCurve(to: CGPoint(x: 19.46, y: 22.6), controlPoint1: CGPoint(x: 19.74, y: 22.53), controlPoint2: CGPoint(x: 19.6, y: 22.6))
        bezier2Path.addCurve(to: CGPoint(x: 18.94, y: 22.08), controlPoint1: CGPoint(x: 19.17, y: 22.6), controlPoint2: CGPoint(x: 18.94, y: 22.37))
        bezier2Path.addCurve(to: CGPoint(x: 18.98, y: 21.89), controlPoint1: CGPoint(x: 18.94, y: 22.01), controlPoint2: CGPoint(x: 18.95, y: 21.95))
        bezier2Path.addLine(to: CGPoint(x: 18.98, y: 21.89))
        bezier2Path.addLine(to: CGPoint(x: 19.97, y: 19.16))
        bezier2Path.addLine(to: CGPoint(x: 19.97, y: 19.16))
        bezier2Path.addCurve(to: CGPoint(x: 19.97, y: 19.07), controlPoint1: CGPoint(x: 19.97, y: 19.14), controlPoint2: CGPoint(x: 19.97, y: 19.1))
        bezier2Path.addCurve(to: CGPoint(x: 19.45, y: 18.59), controlPoint1: CGPoint(x: 19.97, y: 18.78), controlPoint2: CGPoint(x: 19.74, y: 18.59))
        bezier2Path.addCurve(to: CGPoint(x: 19.25, y: 18.58), controlPoint1: CGPoint(x: 19.38, y: 18.59), controlPoint2: CGPoint(x: 19.31, y: 18.58))
        bezier2Path.addLine(to: CGPoint(x: 19.25, y: 18.58))
        bezier2Path.addLine(to: CGPoint(x: 17.99, y: 18.59))
        bezier2Path.usesEvenOddFillRule = true
        primaryColor.setFill()
        bezier2Path.fill()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 11.03, y: 27))
        bezier3Path.addLine(to: CGPoint(x: 11.03, y: 22.87))
        bezier3Path.addCurve(to: CGPoint(x: 13, y: 18.61), controlPoint1: CGPoint(x: 11.03, y: 21.23), controlPoint2: CGPoint(x: 11.73, y: 19.65))
        bezier3Path.addCurve(to: CGPoint(x: 17.84, y: 16.61), controlPoint1: CGPoint(x: 14.23, y: 17.61), controlPoint2: CGPoint(x: 15.93, y: 16.61))
        bezier3Path.addLine(to: CGPoint(x: 20.03, y: 16.61))
        primaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.stroke()
    }

    @objc dynamic public class func drawLane_straight(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: 13, y: 11, width: 4, height: 16))
        primaryColor.setFill()
        rectanglePath.fill()

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 13.01, y: 12.92))
        bezierPath.addLine(to: CGPoint(x: 13.02, y: 11.66))
        bezierPath.addLine(to: CGPoint(x: 13.01, y: 11.66))
        bezierPath.addCurve(to: CGPoint(x: 13.01, y: 11.46), controlPoint1: CGPoint(x: 13.01, y: 11.6), controlPoint2: CGPoint(x: 13.01, y: 11.53))
        bezierPath.addCurve(to: CGPoint(x: 12.53, y: 10.94), controlPoint1: CGPoint(x: 13.01, y: 11.17), controlPoint2: CGPoint(x: 12.82, y: 10.94))
        bezierPath.addCurve(to: CGPoint(x: 12.43, y: 10.94), controlPoint1: CGPoint(x: 12.5, y: 10.94), controlPoint2: CGPoint(x: 12.46, y: 10.94))
        bezierPath.addLine(to: CGPoint(x: 12.44, y: 10.94))
        bezierPath.addLine(to: CGPoint(x: 9.71, y: 11.93))
        bezierPath.addLine(to: CGPoint(x: 9.71, y: 11.93))
        bezierPath.addCurve(to: CGPoint(x: 9.52, y: 11.97), controlPoint1: CGPoint(x: 9.65, y: 11.96), controlPoint2: CGPoint(x: 9.59, y: 11.97))
        bezierPath.addCurve(to: CGPoint(x: 9, y: 11.45), controlPoint1: CGPoint(x: 9.23, y: 11.97), controlPoint2: CGPoint(x: 9, y: 11.74))
        bezierPath.addCurve(to: CGPoint(x: 9.16, y: 11.07), controlPoint1: CGPoint(x: 9, y: 11.3), controlPoint2: CGPoint(x: 9.06, y: 11.17))
        bezierPath.addLine(to: CGPoint(x: 9.16, y: 11.08))
        bezierPath.addLine(to: CGPoint(x: 15.02, y: 3))
        bezierPath.addLine(to: CGPoint(x: 20.86, y: 11.14))
        bezierPath.addLine(to: CGPoint(x: 20.86, y: 11.14))
        bezierPath.addCurve(to: CGPoint(x: 21.02, y: 11.52), controlPoint1: CGPoint(x: 20.96, y: 11.23), controlPoint2: CGPoint(x: 21.02, y: 11.37))
        bezierPath.addCurve(to: CGPoint(x: 20.5, y: 12.03), controlPoint1: CGPoint(x: 21.02, y: 11.8), controlPoint2: CGPoint(x: 20.79, y: 12.03))
        bezierPath.addCurve(to: CGPoint(x: 20.31, y: 11.99), controlPoint1: CGPoint(x: 20.43, y: 12.03), controlPoint2: CGPoint(x: 20.37, y: 12.02))
        bezierPath.addLine(to: CGPoint(x: 20.31, y: 11.99))
        bezierPath.addLine(to: CGPoint(x: 17.58, y: 11))
        bezierPath.addLine(to: CGPoint(x: 17.59, y: 11.01))
        bezierPath.addCurve(to: CGPoint(x: 17.49, y: 11), controlPoint1: CGPoint(x: 17.56, y: 11), controlPoint2: CGPoint(x: 17.52, y: 11))
        bezierPath.addCurve(to: CGPoint(x: 17.01, y: 11.52), controlPoint1: CGPoint(x: 17.2, y: 11), controlPoint2: CGPoint(x: 17.01, y: 11.23))
        bezierPath.addCurve(to: CGPoint(x: 17.01, y: 11.73), controlPoint1: CGPoint(x: 17.01, y: 11.59), controlPoint2: CGPoint(x: 17.01, y: 11.66))
        bezierPath.addLine(to: CGPoint(x: 17, y: 11.72))
        bezierPath.addLine(to: CGPoint(x: 17.01, y: 12.99))
        bezierPath.usesEvenOddFillRule = true
        primaryColor.setFill()
        bezierPath.fill()
    }

    @objc dynamic public class func drawLane_uturn(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 19, y: 20))
        bezierPath.addLine(to: CGPoint(x: 19, y: 11.26))
        bezierPath.addCurve(to: CGPoint(x: 14, y: 5), controlPoint1: CGPoint(x: 19, y: 9.62), controlPoint2: CGPoint(x: 19, y: 5))
        bezierPath.addCurve(to: CGPoint(x: 9, y: 11), controlPoint1: CGPoint(x: 9, y: 5), controlPoint2: CGPoint(x: 9, y: 11))
        bezierPath.addLine(to: CGPoint(x: 9, y: 27))
        primaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 21.02, y: 18.05))
        bezier2Path.addCurve(to: CGPoint(x: 21.01, y: 19.31), controlPoint1: CGPoint(x: 21.02, y: 18.05), controlPoint2: CGPoint(x: 21.01, y: 19.22))
        bezier2Path.addCurve(to: CGPoint(x: 21.02, y: 19.51), controlPoint1: CGPoint(x: 21.02, y: 19.37), controlPoint2: CGPoint(x: 21.02, y: 19.44))
        bezier2Path.addCurve(to: CGPoint(x: 21.5, y: 20.03), controlPoint1: CGPoint(x: 21.02, y: 19.8), controlPoint2: CGPoint(x: 21.21, y: 20.03))
        bezier2Path.addCurve(to: CGPoint(x: 24.32, y: 19.04), controlPoint1: CGPoint(x: 21.71, y: 19.99), controlPoint2: CGPoint(x: 24.21, y: 19.08))
        bezier2Path.addCurve(to: CGPoint(x: 24.51, y: 19), controlPoint1: CGPoint(x: 24.38, y: 19.02), controlPoint2: CGPoint(x: 24.45, y: 19))
        bezier2Path.addCurve(to: CGPoint(x: 25, y: 19.34), controlPoint1: CGPoint(x: 24.74, y: 19), controlPoint2: CGPoint(x: 24.93, y: 19.15))
        bezier2Path.addLine(to: CGPoint(x: 25, y: 19.52))
        bezier2Path.addLine(to: CGPoint(x: 25, y: 19.69))
        bezier2Path.addCurve(to: CGPoint(x: 24.87, y: 19.89), controlPoint1: CGPoint(x: 24.97, y: 19.77), controlPoint2: CGPoint(x: 24.93, y: 19.84))
        bezier2Path.addCurve(to: CGPoint(x: 19.02, y: 26.97), controlPoint1: CGPoint(x: 24.74, y: 20.05), controlPoint2: CGPoint(x: 19.02, y: 26.97))
        bezier2Path.addCurve(to: CGPoint(x: 15.31, y: 22.44), controlPoint1: CGPoint(x: 19.02, y: 26.97), controlPoint2: CGPoint(x: 16.98, y: 24.48))
        bezier2Path.addCurve(to: CGPoint(x: 13.17, y: 19.84), controlPoint1: CGPoint(x: 14.18, y: 21.07), controlPoint2: CGPoint(x: 13.23, y: 19.9))
        bezier2Path.addCurve(to: CGPoint(x: 13.01, y: 19.46), controlPoint1: CGPoint(x: 13.07, y: 19.74), controlPoint2: CGPoint(x: 13.01, y: 19.6))
        bezier2Path.addCurve(to: CGPoint(x: 13.53, y: 18.94), controlPoint1: CGPoint(x: 13.01, y: 19.17), controlPoint2: CGPoint(x: 13.24, y: 18.94))
        bezier2Path.addCurve(to: CGPoint(x: 13.72, y: 18.98), controlPoint1: CGPoint(x: 13.6, y: 18.94), controlPoint2: CGPoint(x: 13.66, y: 18.95))
        bezier2Path.addCurve(to: CGPoint(x: 16.44, y: 19.97), controlPoint1: CGPoint(x: 13.83, y: 19.02), controlPoint2: CGPoint(x: 16.34, y: 19.93))
        bezier2Path.addCurve(to: CGPoint(x: 17.02, y: 19.45), controlPoint1: CGPoint(x: 16.83, y: 19.97), controlPoint2: CGPoint(x: 17.02, y: 19.74))
        bezier2Path.addCurve(to: CGPoint(x: 17.03, y: 19.25), controlPoint1: CGPoint(x: 17.02, y: 19.38), controlPoint2: CGPoint(x: 17.03, y: 19.31))
        bezier2Path.addCurve(to: CGPoint(x: 17.02, y: 17.99), controlPoint1: CGPoint(x: 17.03, y: 19.17), controlPoint2: CGPoint(x: 17.02, y: 17.99))
        bezier2Path.addLine(to: CGPoint(x: 21.02, y: 18.05))
        bezier2Path.close()
        primaryColor.setFill()
        bezier2Path.fill()
    }

    @objc dynamic public class func drawLane_slight_right(primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), scale: CGFloat = 1) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!

        //// Group 3
        context.saveGState()
        context.translateBy(x: 21.78, y: 10.24)
        context.scaleBy(x: scale, y: scale)

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: -5.33, y: -0.49))
        bezier3Path.addLine(to: CGPoint(x: -11.03, y: 4.79))
        bezier3Path.addCurve(to: CGPoint(x: -12.5, y: 9.37), controlPoint1: CGPoint(x: -11.9, y: 6.11), controlPoint2: CGPoint(x: -12.5, y: 7.72))
        bezier3Path.addLine(to: CGPoint(x: -12.5, y: 16.5))
        primaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.lineJoinStyle = .round
        bezier3Path.stroke()

        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: -2.25, y: -11.1)
        context.rotate(by: 49 * CGFloat.pi/180)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 4.01, y: 9.92))
        bezierPath.addLine(to: CGPoint(x: 4.02, y: 8.66))
        bezierPath.addLine(to: CGPoint(x: 4.01, y: 8.66))
        bezierPath.addCurve(to: CGPoint(x: 4.01, y: 8.46), controlPoint1: CGPoint(x: 4.01, y: 8.6), controlPoint2: CGPoint(x: 4.01, y: 8.53))
        bezierPath.addCurve(to: CGPoint(x: 3.53, y: 7.94), controlPoint1: CGPoint(x: 4.01, y: 8.17), controlPoint2: CGPoint(x: 3.82, y: 7.94))
        bezierPath.addCurve(to: CGPoint(x: 3.43, y: 7.94), controlPoint1: CGPoint(x: 3.5, y: 7.94), controlPoint2: CGPoint(x: 3.46, y: 7.94))
        bezierPath.addLine(to: CGPoint(x: 3.44, y: 7.94))
        bezierPath.addLine(to: CGPoint(x: 0.71, y: 8.93))
        bezierPath.addLine(to: CGPoint(x: 0.71, y: 8.93))
        bezierPath.addCurve(to: CGPoint(x: 0.52, y: 8.97), controlPoint1: CGPoint(x: 0.65, y: 8.96), controlPoint2: CGPoint(x: 0.58, y: 8.97))
        bezierPath.addCurve(to: CGPoint(x: 0, y: 8.45), controlPoint1: CGPoint(x: 0.23, y: 8.97), controlPoint2: CGPoint(x: 0, y: 8.74))
        bezierPath.addCurve(to: CGPoint(x: 0.16, y: 8.07), controlPoint1: CGPoint(x: 0, y: 8.3), controlPoint2: CGPoint(x: 0.06, y: 8.17))
        bezierPath.addLine(to: CGPoint(x: 0.16, y: 8.08))
        bezierPath.addLine(to: CGPoint(x: 6.02, y: 0))
        bezierPath.addLine(to: CGPoint(x: 11.86, y: 8.14))
        bezierPath.addLine(to: CGPoint(x: 11.86, y: 8.14))
        bezierPath.addCurve(to: CGPoint(x: 12.02, y: 8.52), controlPoint1: CGPoint(x: 11.96, y: 8.23), controlPoint2: CGPoint(x: 12.02, y: 8.37))
        bezierPath.addCurve(to: CGPoint(x: 11.5, y: 9.03), controlPoint1: CGPoint(x: 12.02, y: 8.8), controlPoint2: CGPoint(x: 11.79, y: 9.03))
        bezierPath.addCurve(to: CGPoint(x: 11.31, y: 8.99), controlPoint1: CGPoint(x: 11.43, y: 9.03), controlPoint2: CGPoint(x: 11.37, y: 9.02))
        bezierPath.addLine(to: CGPoint(x: 11.31, y: 8.99))
        bezierPath.addLine(to: CGPoint(x: 8.58, y: 8))
        bezierPath.addLine(to: CGPoint(x: 8.59, y: 8.01))
        bezierPath.addCurve(to: CGPoint(x: 8.49, y: 8), controlPoint1: CGPoint(x: 8.56, y: 8), controlPoint2: CGPoint(x: 8.52, y: 8))
        bezierPath.addCurve(to: CGPoint(x: 8.01, y: 8.53), controlPoint1: CGPoint(x: 8.2, y: 8), controlPoint2: CGPoint(x: 8.01, y: 8.23))
        bezierPath.addCurve(to: CGPoint(x: 8.01, y: 8.73), controlPoint1: CGPoint(x: 8.01, y: 8.59), controlPoint2: CGPoint(x: 8.01, y: 8.66))
        bezierPath.addLine(to: CGPoint(x: 8, y: 8.72))
        bezierPath.addLine(to: CGPoint(x: 8.01, y: 9.99))
        bezierPath.usesEvenOddFillRule = true
        primaryColor.setFill()
        bezierPath.fill()

        context.restoreGState()

        context.restoreGState()
    }

}
