import UIKit

/// :nodoc:
public class ManeuversStyleKit: NSObject {

    // MARK: Drawing Methods

    @objc dynamic public class func drawArrow180right(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 2
        context.saveGState()
        context.translateBy(x: x, y: (y + 1))
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -3.36, y: 2.8))
        bezierPath.addLine(to: CGPoint(x: 5.51, y: 14.99))
        bezierPath.addLine(to: CGPoint(x: 14.37, y: 2.8))
        bezierPath.addCurve(to: CGPoint(x: 14.51, y: 2.46), controlPoint1: CGPoint(x: 14.45, y: 2.71), controlPoint2: CGPoint(x: 14.51, y: 2.59))
        bezierPath.addCurve(to: CGPoint(x: 14.01, y: 1.96), controlPoint1: CGPoint(x: 14.51, y: 2.19), controlPoint2: CGPoint(x: 14.28, y: 1.96))
        bezierPath.addCurve(to: CGPoint(x: 13.89, y: 1.97), controlPoint1: CGPoint(x: 13.97, y: 1.96), controlPoint2: CGPoint(x: 13.89, y: 1.97))
        bezierPath.addLine(to: CGPoint(x: 8.15, y: 3.94))
        bezierPath.addCurve(to: CGPoint(x: 8.01, y: 3.96), controlPoint1: CGPoint(x: 8.11, y: 3.95), controlPoint2: CGPoint(x: 8.06, y: 3.96))
        bezierPath.addCurve(to: CGPoint(x: 7.51, y: 3.5), controlPoint1: CGPoint(x: 7.74, y: 3.96), controlPoint2: CGPoint(x: 7.51, y: 3.76))
        bezierPath.addCurve(to: CGPoint(x: 7.51, y: 1), controlPoint1: CGPoint(x: 7.51, y: 3.13), controlPoint2: CGPoint(x: 7.51, y: 1))
        bezierPath.addLine(to: CGPoint(x: 5.51, y: 1))
        bezierPath.addLine(to: CGPoint(x: 3.5, y: 1))
        bezierPath.addCurve(to: CGPoint(x: 3.51, y: 3.5), controlPoint1: CGPoint(x: 3.5, y: 1), controlPoint2: CGPoint(x: 3.51, y: 3.13))
        bezierPath.addCurve(to: CGPoint(x: 3.01, y: 3.97), controlPoint1: CGPoint(x: 3.51, y: 3.76), controlPoint2: CGPoint(x: 3.28, y: 3.97))
        bezierPath.addCurve(to: CGPoint(x: 2.86, y: 3.95), controlPoint1: CGPoint(x: 2.96, y: 3.97), controlPoint2: CGPoint(x: 2.91, y: 3.96))
        bezierPath.addLine(to: CGPoint(x: -2.88, y: 1.98))
        bezierPath.addCurve(to: CGPoint(x: -2.99, y: 1.96), controlPoint1: CGPoint(x: -2.88, y: 1.98), controlPoint2: CGPoint(x: -2.95, y: 1.96))
        bezierPath.addCurve(to: CGPoint(x: -3.49, y: 2.46), controlPoint1: CGPoint(x: -3.27, y: 1.96), controlPoint2: CGPoint(x: -3.49, y: 2.19))
        bezierPath.addCurve(to: CGPoint(x: -3.36, y: 2.8), controlPoint1: CGPoint(x: -3.49, y: 2.59), controlPoint2: CGPoint(x: -3.44, y: 2.71))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -7.5, y: 15))
        bezier2Path.addLine(to: CGPoint(x: -7.5, y: -5.16))
        bezier2Path.addCurve(to: CGPoint(x: -1, y: -12), controlPoint1: CGPoint(x: -7.5, y: -8.91), controlPoint2: CGPoint(x: -4.55, y: -12))
        bezier2Path.addCurve(to: CGPoint(x: 5.5, y: -5.15), controlPoint1: CGPoint(x: 2.59, y: -12), controlPoint2: CGPoint(x: 5.5, y: -8.72))
        bezier2Path.addLine(to: CGPoint(x: 5.5, y: 4))
        primaryColor.setStroke()
        bezier2Path.lineWidth = 4
        bezier2Path.stroke()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArrowright(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: x, y: (y + 1))
        context.scaleBy(x: scale, y: scale)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -10.01, y: 15.01))
        bezierPath.addLine(to: CGPoint(x: -10.01, y: 1))
        bezierPath.addCurve(to: CGPoint(x: -5.05, y: -3.99), controlPoint1: CGPoint(x: -10.01, y: 0.49), controlPoint2: CGPoint(x: -9.84, y: -3.99))
        bezierPath.addLine(to: CGPoint(x: 2.57, y: -3.99))
        bezierPath.addCurve(to: CGPoint(x: 2.98, y: -3.51), controlPoint1: CGPoint(x: 2.8, y: -3.95), controlPoint2: CGPoint(x: 2.98, y: -3.75))
        bezierPath.addCurve(to: CGPoint(x: 2.96, y: -3.37), controlPoint1: CGPoint(x: 2.98, y: -3.46), controlPoint2: CGPoint(x: 2.97, y: -3.41))
        bezierPath.addLine(to: CGPoint(x: 0.99, y: 2.38))
        bezierPath.addCurve(to: CGPoint(x: 0.98, y: 2.49), controlPoint1: CGPoint(x: 0.99, y: 2.38), controlPoint2: CGPoint(x: 0.98, y: 2.45))
        bezierPath.addCurve(to: CGPoint(x: 1.48, y: 2.99), controlPoint1: CGPoint(x: 0.98, y: 2.77), controlPoint2: CGPoint(x: 1.2, y: 2.99))
        bezierPath.addCurve(to: CGPoint(x: 1.82, y: 2.86), controlPoint1: CGPoint(x: 1.61, y: 2.99), controlPoint2: CGPoint(x: 1.73, y: 2.94))
        bezierPath.addLine(to: CGPoint(x: 14.01, y: -6.01))
        bezierPath.addLine(to: CGPoint(x: 1.82, y: -14.87))
        bezierPath.addCurve(to: CGPoint(x: 1.48, y: -15.01), controlPoint1: CGPoint(x: 1.73, y: -14.95), controlPoint2: CGPoint(x: 1.61, y: -15.01))
        bezierPath.addCurve(to: CGPoint(x: 0.98, y: -14.51), controlPoint1: CGPoint(x: 1.2, y: -15.01), controlPoint2: CGPoint(x: 0.98, y: -14.78))
        bezierPath.addCurve(to: CGPoint(x: 0.99, y: -14.4), controlPoint1: CGPoint(x: 0.98, y: -14.47), controlPoint2: CGPoint(x: 0.99, y: -14.4))
        bezierPath.addLine(to: CGPoint(x: 2.96, y: -8.65))
        bezierPath.addCurve(to: CGPoint(x: 2.98, y: -8.51), controlPoint1: CGPoint(x: 2.97, y: -8.6), controlPoint2: CGPoint(x: 2.98, y: -8.56))
        bezierPath.addCurve(to: CGPoint(x: 2.5, y: -8.01), controlPoint1: CGPoint(x: 2.98, y: -8.24), controlPoint2: CGPoint(x: 2.76, y: -8.01))
        bezierPath.addCurve(to: CGPoint(x: -5.05, y: -7.99), controlPoint1: CGPoint(x: 2.14, y: -8.01), controlPoint2: CGPoint(x: -5.05, y: -7.99))
        bezierPath.addCurve(to: CGPoint(x: -14.01, y: 0.99), controlPoint1: CGPoint(x: -11.58, y: -7.99), controlPoint2: CGPoint(x: -13.99, y: -2.63))
        bezierPath.addLine(to: CGPoint(x: -14.01, y: 15.01))
        primaryColor.setFill()
        bezierPath.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArrowslightright(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 3
        context.saveGState()
        context.translateBy(x: (x + 1), y: (y + 1))
        context.scaleBy(x: scale, y: scale)

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 0.99, y: -5.09))
        bezier3Path.addLine(to: CGPoint(x: -6.55, y: 1.88))
        bezier3Path.addCurve(to: CGPoint(x: -8.34, y: 7.93), controlPoint1: CGPoint(x: -7.71, y: 3.63), controlPoint2: CGPoint(x: -8.34, y: 5.75))
        bezier3Path.addLine(to: CGPoint(x: -8.34, y: 15.06))
        primaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.lineJoinStyle = .round
        bezier3Path.stroke()

        //// Bezier 4 Drawing
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint(x: -2.97, y: -12.04))
        bezier4Path.addLine(to: CGPoint(x: 9.88, y: -12.76))
        bezier4Path.addLine(to: CGPoint(x: 7.31, y: -0.15))
        bezier4Path.addCurve(to: CGPoint(x: 7.15, y: 0.18), controlPoint1: CGPoint(x: 7.3, y: -0.02), controlPoint2: CGPoint(x: 7.24, y: 0.09))
        bezier4Path.addCurve(to: CGPoint(x: 6.44, y: 0.13), controlPoint1: CGPoint(x: 6.94, y: 0.36), controlPoint2: CGPoint(x: 6.62, y: 0.34))
        bezier4Path.addCurve(to: CGPoint(x: 6.38, y: 0.03), controlPoint1: CGPoint(x: 6.41, y: 0.1), controlPoint2: CGPoint(x: 6.38, y: 0.03))
        bezier4Path.addLine(to: CGPoint(x: 4, y: -4.19))
        bezier4Path.addCurve(to: CGPoint(x: 3.93, y: -4.31), controlPoint1: CGPoint(x: 3.99, y: -4.23), controlPoint2: CGPoint(x: 3.96, y: -4.27))
        bezier4Path.addCurve(to: CGPoint(x: 3.05, y: -4.21), controlPoint1: CGPoint(x: 3.75, y: -4.51), controlPoint2: CGPoint(x: 3.25, y: -4.38))
        bezier4Path.addCurve(to: CGPoint(x: 0.97, y: -2.41), controlPoint1: CGPoint(x: 2.78, y: -3.98), controlPoint2: CGPoint(x: 0.97, y: -2.41))
        bezier4Path.addLine(to: CGPoint(x: -0.34, y: -3.92))
        bezier4Path.addLine(to: CGPoint(x: -1.65, y: -5.44))
        bezier4Path.addCurve(to: CGPoint(x: 0.43, y: -7.24), controlPoint1: CGPoint(x: -1.65, y: -5.44), controlPoint2: CGPoint(x: 0.16, y: -7))
        bezier4Path.addCurve(to: CGPoint(x: 0.57, y: -8.01), controlPoint1: CGPoint(x: 0.63, y: -7.41), controlPoint2: CGPoint(x: 0.74, y: -7.81))
        bezier4Path.addCurve(to: CGPoint(x: 0.5, y: -8.15), controlPoint1: CGPoint(x: 0.53, y: -8.05), controlPoint2: CGPoint(x: 0.54, y: -8.12))
        bezier4Path.addLine(to: CGPoint(x: -3.31, y: -11.12))
        bezier4Path.addCurve(to: CGPoint(x: -3.38, y: -11.21), controlPoint1: CGPoint(x: -3.31, y: -11.12), controlPoint2: CGPoint(x: -3.36, y: -11.18))
        bezier4Path.addCurve(to: CGPoint(x: -3.32, y: -11.92), controlPoint1: CGPoint(x: -3.56, y: -11.42), controlPoint2: CGPoint(x: -3.53, y: -11.74))
        bezier4Path.addCurve(to: CGPoint(x: -2.97, y: -12.04), controlPoint1: CGPoint(x: -3.22, y: -12.01), controlPoint2: CGPoint(x: -3.09, y: -12.05))
        bezier4Path.close()
        primaryColor.setFill()
        bezier4Path.fill()

        //// Clip Drawing

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArrowstraight(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: x, y: (y + 1))
        context.scaleBy(x: scale, y: scale)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 8.86, y: -2.82))
        bezierPath.addLine(to: CGPoint(x: 0, y: -15.02))
        bezierPath.addLine(to: CGPoint(x: -8.86, y: -2.82))
        bezierPath.addCurve(to: CGPoint(x: -9, y: -2.48), controlPoint1: CGPoint(x: -8.95, y: -2.73), controlPoint2: CGPoint(x: -9, y: -2.62))
        bezierPath.addCurve(to: CGPoint(x: -8.5, y: -1.98), controlPoint1: CGPoint(x: -9, y: -2.21), controlPoint2: CGPoint(x: -8.78, y: -1.98))
        bezierPath.addCurve(to: CGPoint(x: -8.39, y: -2), controlPoint1: CGPoint(x: -8.46, y: -1.98), controlPoint2: CGPoint(x: -8.39, y: -2))
        bezierPath.addLine(to: CGPoint(x: -2.64, y: -3.96))
        bezierPath.addCurve(to: CGPoint(x: -2.5, y: -3.98), controlPoint1: CGPoint(x: -2.6, y: -3.98), controlPoint2: CGPoint(x: -2.55, y: -3.98))
        bezierPath.addCurve(to: CGPoint(x: -2, y: -3.5), controlPoint1: CGPoint(x: -2.23, y: -3.98), controlPoint2: CGPoint(x: -2, y: -3.76))
        bezierPath.addLine(to: CGPoint(x: -2, y: 15.02))
        bezierPath.addLine(to: CGPoint(x: 2, y: 15.02))
        bezierPath.addCurve(to: CGPoint(x: 2, y: -3.5), controlPoint1: CGPoint(x: 2, y: 15.02), controlPoint2: CGPoint(x: 2, y: -3.14))
        bezierPath.addCurve(to: CGPoint(x: 2.5, y: -3.98), controlPoint1: CGPoint(x: 2, y: -3.76), controlPoint2: CGPoint(x: 2.23, y: -3.98))
        bezierPath.addCurve(to: CGPoint(x: 2.64, y: -3.96), controlPoint1: CGPoint(x: 2.55, y: -3.98), controlPoint2: CGPoint(x: 2.6, y: -3.98))
        bezierPath.addLine(to: CGPoint(x: 8.39, y: -2))
        bezierPath.addCurve(to: CGPoint(x: 8.5, y: -1.98), controlPoint1: CGPoint(x: 8.39, y: -2), controlPoint2: CGPoint(x: 8.46, y: -1.98))
        bezierPath.addCurve(to: CGPoint(x: 9, y: -2.48), controlPoint1: CGPoint(x: 8.78, y: -1.98), controlPoint2: CGPoint(x: 9, y: -2.21))
        bezierPath.addCurve(to: CGPoint(x: 8.86, y: -2.82), controlPoint1: CGPoint(x: 9, y: -2.62), controlPoint2: CGPoint(x: 8.95, y: -2.73))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArrowsharpright(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 2
        context.saveGState()
        context.translateBy(x: x, y: y)
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -1.66, y: 4.57))
        bezierPath.addLine(to: CGPoint(x: 13.13, y: 7.5))
        bezierPath.addLine(to: CGPoint(x: 11.36, y: -7.47))
        bezierPath.addCurve(to: CGPoint(x: 11.23, y: -7.81), controlPoint1: CGPoint(x: 11.36, y: -7.59), controlPoint2: CGPoint(x: 11.32, y: -7.71))
        bezierPath.addCurve(to: CGPoint(x: 10.52, y: -7.84), controlPoint1: CGPoint(x: 11.04, y: -8.01), controlPoint2: CGPoint(x: 10.73, y: -8.03))
        bezierPath.addCurve(to: CGPoint(x: 10.45, y: -7.75), controlPoint1: CGPoint(x: 10.49, y: -7.81), controlPoint2: CGPoint(x: 10.45, y: -7.75))
        bezierPath.addLine(to: CGPoint(x: 7.57, y: -2.41))
        bezierPath.addCurve(to: CGPoint(x: 7.48, y: -2.3), controlPoint1: CGPoint(x: 7.54, y: -2.37), controlPoint2: CGPoint(x: 7.51, y: -2.33))
        bezierPath.addCurve(to: CGPoint(x: 6.78, y: -2.31), controlPoint1: CGPoint(x: 7.28, y: -2.11), controlPoint2: CGPoint(x: 6.96, y: -2.12))
        bezierPath.addCurve(to: CGPoint(x: 5.09, y: -4.15), controlPoint1: CGPoint(x: 6.54, y: -2.57), controlPoint2: CGPoint(x: 5.09, y: -4.15))
        bezierPath.addLine(to: CGPoint(x: 3.61, y: -2.79))
        bezierPath.addLine(to: CGPoint(x: 2.14, y: -1.43))
        bezierPath.addCurve(to: CGPoint(x: 3.85, y: 0.41), controlPoint1: CGPoint(x: 2.14, y: -1.43), controlPoint2: CGPoint(x: 3.6, y: 0.14))
        bezierPath.addCurve(to: CGPoint(x: 3.81, y: 1.1), controlPoint1: CGPoint(x: 4.02, y: 0.6), controlPoint2: CGPoint(x: 4.01, y: 0.92))
        bezierPath.addCurve(to: CGPoint(x: 3.69, y: 1.18), controlPoint1: CGPoint(x: 3.77, y: 1.14), controlPoint2: CGPoint(x: 3.73, y: 1.16))
        bezierPath.addLine(to: CGPoint(x: -1.87, y: 3.64))
        bezierPath.addCurve(to: CGPoint(x: -1.96, y: 3.7), controlPoint1: CGPoint(x: -1.87, y: 3.64), controlPoint2: CGPoint(x: -1.93, y: 3.68))
        bezierPath.addCurve(to: CGPoint(x: -1.99, y: 4.41), controlPoint1: CGPoint(x: -2.16, y: 3.89), controlPoint2: CGPoint(x: -2.17, y: 4.21))
        bezierPath.addCurve(to: CGPoint(x: -1.66, y: 4.57), controlPoint1: CGPoint(x: -1.9, y: 4.51), controlPoint2: CGPoint(x: -1.78, y: 4.56))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: -11.12, y: -4))
        bezier3Path.addCurve(to: CGPoint(x: -6.62, y: -8.5), controlPoint1: CGPoint(x: -11.12, y: -4), controlPoint2: CGPoint(x: -11.33, y: -8.5))
        bezier3Path.addCurve(to: CGPoint(x: 1.88, y: -4.5), controlPoint1: CGPoint(x: -1.91, y: -8.5), controlPoint2: CGPoint(x: 1.88, y: -4.5))
        bezier3Path.addLine(to: CGPoint(x: 4.88, y: -1.5))
        bezier3Path.move(to: CGPoint(x: -11.12, y: -4.5))
        bezier3Path.addLine(to: CGPoint(x: -11.12, y: 1.5))
        bezier3Path.move(to: CGPoint(x: -11.12, y: 1.5))
        bezier3Path.addLine(to: CGPoint(x: -11.12, y: 3.5))
        bezier3Path.move(to: CGPoint(x: -11.12, y: 3.5))
        bezier3Path.addLine(to: CGPoint(x: -11.12, y: 12.98))
        bezier3Path.addLine(to: CGPoint(x: -11.12, y: 16))
        primaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.stroke()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArrive(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 2
        context.saveGState()
        context.translateBy(x: x, y: (y + 1))
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0.06, y: 6.6))
        bezierPath.addLine(to: CGPoint(x: 0.06, y: 15))
        primaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -2, y: 2.48))
        bezier2Path.addCurve(to: CGPoint(x: -2, y: 1.73), controlPoint1: CGPoint(x: -2, y: 2.48), controlPoint2: CGPoint(x: -2, y: 2.09))
        bezier2Path.addCurve(to: CGPoint(x: -2.5, y: 1.12), controlPoint1: CGPoint(x: -2, y: 1.46), controlPoint2: CGPoint(x: -2.23, y: 1.12))
        bezier2Path.addCurve(to: CGPoint(x: -2.64, y: 1.08), controlPoint1: CGPoint(x: -2.55, y: 1.12), controlPoint2: CGPoint(x: -2.6, y: 1.07))
        bezier2Path.addLine(to: CGPoint(x: -7.39, y: 2.02))
        bezier2Path.addCurve(to: CGPoint(x: -7.5, y: 2.01), controlPoint1: CGPoint(x: -7.39, y: 2.02), controlPoint2: CGPoint(x: -7.46, y: 2.01))
        bezier2Path.addCurve(to: CGPoint(x: -8, y: 1.51), controlPoint1: CGPoint(x: -7.78, y: 2.01), controlPoint2: CGPoint(x: -8, y: 1.78))
        bezier2Path.addCurve(to: CGPoint(x: -7.86, y: 1.16), controlPoint1: CGPoint(x: -8, y: 1.37), controlPoint2: CGPoint(x: -7.95, y: 1.25))
        bezier2Path.addLine(to: CGPoint(x: 0, y: -9.03))
        bezier2Path.addLine(to: CGPoint(x: 7.86, y: 1.16))
        bezier2Path.addCurve(to: CGPoint(x: 8, y: 1.5), controlPoint1: CGPoint(x: 7.95, y: 1.25), controlPoint2: CGPoint(x: 8, y: 1.37))
        bezier2Path.addCurve(to: CGPoint(x: 7.5, y: 2), controlPoint1: CGPoint(x: 8, y: 1.77), controlPoint2: CGPoint(x: 7.78, y: 2))
        bezier2Path.addCurve(to: CGPoint(x: 7.39, y: 1.99), controlPoint1: CGPoint(x: 7.46, y: 2), controlPoint2: CGPoint(x: 7.39, y: 1.99))
        bezier2Path.addLine(to: CGPoint(x: 2.64, y: 1.02))
        bezier2Path.addCurve(to: CGPoint(x: 2.5, y: 1), controlPoint1: CGPoint(x: 2.6, y: 1.01), controlPoint2: CGPoint(x: 2.55, y: 1))
        bezier2Path.addCurve(to: CGPoint(x: 2, y: 1.73), controlPoint1: CGPoint(x: 2.23, y: 1), controlPoint2: CGPoint(x: 2, y: 1.46))
        bezier2Path.addCurve(to: CGPoint(x: 2, y: 2.48), controlPoint1: CGPoint(x: 2, y: 2.09), controlPoint2: CGPoint(x: 2, y: 2.48))
        primaryColor.setFill()
        bezier2Path.fill()

        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: -3, y: -16.6, width: 6.1, height: 6.1))
        primaryColor.setFill()
        ovalPath.fill()

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: -2, y: 3.62, width: 4, height: 1.95))
        primaryColor.setFill()
        rectanglePath.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawStarting(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Bezier 2 Drawing
        context.saveGState()
        context.translateBy(x: x, y: y)
        context.scaleBy(x: scale, y: scale)

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 0, y: -10.5))
        bezier2Path.addLine(to: CGPoint(x: -10, y: 10.5))
        bezier2Path.addLine(to: CGPoint(x: 0.07, y: 4.2))
        bezier2Path.addLine(to: CGPoint(x: 10, y: 10.5))
        bezier2Path.addLine(to: CGPoint(x: 0, y: -10.5))
        bezier2Path.close()
        bezier2Path.usesEvenOddFillRule = true
        primaryColor.setFill()
        bezier2Path.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawDestination(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: x, y: y)
        context.scaleBy(x: scale, y: scale)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: -7))
        bezierPath.addCurve(to: CGPoint(x: -0.97, y: -6.84), controlPoint1: CGPoint(x: -0.34, y: -7), controlPoint2: CGPoint(x: -0.66, y: -6.94))
        bezierPath.addCurve(to: CGPoint(x: -3, y: -4), controlPoint1: CGPoint(x: -2.15, y: -6.44), controlPoint2: CGPoint(x: -3, y: -5.32))
        bezierPath.addCurve(to: CGPoint(x: 0, y: -1), controlPoint1: CGPoint(x: -3, y: -2.34), controlPoint2: CGPoint(x: -1.66, y: -1))
        bezierPath.addCurve(to: CGPoint(x: 3, y: -4), controlPoint1: CGPoint(x: 1.66, y: -1), controlPoint2: CGPoint(x: 3, y: -2.34))
        bezierPath.addCurve(to: CGPoint(x: 0, y: -7), controlPoint1: CGPoint(x: 3, y: -5.66), controlPoint2: CGPoint(x: 1.66, y: -7))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: 8, y: -4))
        bezierPath.addCurve(to: CGPoint(x: 0, y: 12), controlPoint1: CGPoint(x: 8, y: 0.42), controlPoint2: CGPoint(x: 4, y: 3))
        bezierPath.addCurve(to: CGPoint(x: -8, y: -4), controlPoint1: CGPoint(x: -4, y: 3), controlPoint2: CGPoint(x: -8, y: 0.42))
        bezierPath.addCurve(to: CGPoint(x: -5.35, y: -9.95), controlPoint1: CGPoint(x: -8, y: -6.36), controlPoint2: CGPoint(x: -6.98, y: -8.49))
        bezierPath.addCurve(to: CGPoint(x: -3.63, y: -11.13), controlPoint1: CGPoint(x: -4.83, y: -10.42), controlPoint2: CGPoint(x: -4.25, y: -10.81))
        bezierPath.addCurve(to: CGPoint(x: 0, y: -12), controlPoint1: CGPoint(x: -2.54, y: -11.69), controlPoint2: CGPoint(x: -1.31, y: -12))
        bezierPath.addCurve(to: CGPoint(x: 8, y: -4), controlPoint1: CGPoint(x: 4.42, y: -12), controlPoint2: CGPoint(x: 8, y: -8.42))
        bezierPath.close()
        primaryColor.setFill()
        bezierPath.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawMerge(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), secondaryColor: UIColor = UIColor(red: 0.618, green: 0.618, blue: 0.618, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 3
        context.saveGState()
        context.translateBy(x: x, y: (y + 1))
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 8.07, y: 15))
        bezierPath.addLine(to: CGPoint(x: 8.07, y: 12.47))
        bezierPath.addCurve(to: CGPoint(x: 6.28, y: 7.1), controlPoint1: CGPoint(x: 8.07, y: 10.53), controlPoint2: CGPoint(x: 7.44, y: 8.65))
        bezierPath.addLine(to: CGPoint(x: 1.86, y: 1.19))
        bezierPath.addCurve(to: CGPoint(x: 0.07, y: -4.19), controlPoint1: CGPoint(x: 0.69, y: -0.36), controlPoint2: CGPoint(x: 0.07, y: -2.25))
        bezierPath.addLine(to: CGPoint(x: 0.07, y: -10.51))
        secondaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -8.06, y: 15))
        bezier2Path.addLine(to: CGPoint(x: -8.06, y: 12.39))
        bezier2Path.addCurve(to: CGPoint(x: -6.27, y: 7.01), controlPoint1: CGPoint(x: -8.06, y: 10.45), controlPoint2: CGPoint(x: -7.43, y: 8.56))
        bezier2Path.addLine(to: CGPoint(x: -1.85, y: 1.11))
        bezier2Path.addCurve(to: CGPoint(x: -0.06, y: -4.27), controlPoint1: CGPoint(x: -0.69, y: -0.45), controlPoint2: CGPoint(x: -0.06, y: -2.33))
        bezier2Path.addLine(to: CGPoint(x: -0.06, y: -10.6))
        primaryColor.setStroke()
        bezier2Path.lineWidth = 4
        bezier2Path.lineJoinStyle = .round
        bezier2Path.stroke()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 7.8, y: -6.29))
        bezier3Path.addLine(to: CGPoint(x: -0.07, y: -16.48))
        bezier3Path.addLine(to: CGPoint(x: -7.93, y: -6.29))
        bezier3Path.addCurve(to: CGPoint(x: -8.07, y: -5.95), controlPoint1: CGPoint(x: -8.01, y: -6.2), controlPoint2: CGPoint(x: -8.07, y: -6.08))
        bezier3Path.addCurve(to: CGPoint(x: -7.57, y: -5.45), controlPoint1: CGPoint(x: -8.07, y: -5.67), controlPoint2: CGPoint(x: -7.84, y: -5.45))
        bezier3Path.addCurve(to: CGPoint(x: -7.45, y: -5.46), controlPoint1: CGPoint(x: -7.53, y: -5.45), controlPoint2: CGPoint(x: -7.45, y: -5.46))
        bezier3Path.addLine(to: CGPoint(x: -2.71, y: -6.43))
        bezier3Path.addCurve(to: CGPoint(x: -2.57, y: -6.45), controlPoint1: CGPoint(x: -2.66, y: -6.44), controlPoint2: CGPoint(x: -2.62, y: -6.45))
        bezier3Path.addCurve(to: CGPoint(x: -2.07, y: -5.72), controlPoint1: CGPoint(x: -2.3, y: -6.45), controlPoint2: CGPoint(x: -2.07, y: -5.98))
        bezier3Path.addCurve(to: CGPoint(x: -2.07, y: -2.96), controlPoint1: CGPoint(x: -2.07, y: -5.36), controlPoint2: CGPoint(x: -2.07, y: -2.96))
        bezier3Path.addLine(to: CGPoint(x: -0.07, y: -2.96))
        bezier3Path.addLine(to: CGPoint(x: 1.94, y: -2.96))
        bezier3Path.addCurve(to: CGPoint(x: 1.93, y: -5.72), controlPoint1: CGPoint(x: 1.94, y: -2.96), controlPoint2: CGPoint(x: 1.93, y: -5.36))
        bezier3Path.addCurve(to: CGPoint(x: 2.43, y: -6.33), controlPoint1: CGPoint(x: 1.93, y: -5.98), controlPoint2: CGPoint(x: 2.16, y: -6.33))
        bezier3Path.addCurve(to: CGPoint(x: 2.58, y: -6.37), controlPoint1: CGPoint(x: 2.48, y: -6.33), controlPoint2: CGPoint(x: 2.53, y: -6.38))
        bezier3Path.addLine(to: CGPoint(x: 7.32, y: -5.43))
        bezier3Path.addCurve(to: CGPoint(x: 7.43, y: -5.43), controlPoint1: CGPoint(x: 7.32, y: -5.43), controlPoint2: CGPoint(x: 7.4, y: -5.43))
        bezier3Path.addCurve(to: CGPoint(x: 7.93, y: -5.94), controlPoint1: CGPoint(x: 7.71, y: -5.43), controlPoint2: CGPoint(x: 7.93, y: -5.66))
        bezier3Path.addCurve(to: CGPoint(x: 7.8, y: -6.29), controlPoint1: CGPoint(x: 7.93, y: -6.07), controlPoint2: CGPoint(x: 7.88, y: -6.2))
        bezier3Path.close()
        primaryColor.setFill()
        bezier3Path.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawFork(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), secondaryColor: UIColor = UIColor(red: 0.618, green: 0.618, blue: 0.618, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 3
        context.saveGState()
        context.translateBy(x: (x + 2.99260816186), y: y)
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -3.99, y: 16))
        bezierPath.addLine(to: CGPoint(x: -3.99, y: 9))
        bezierPath.addCurve(to: CGPoint(x: -5.9, y: 3.62), controlPoint1: CGPoint(x: -3.99, y: 7.06), controlPoint2: CGPoint(x: -4.74, y: 5.17))
        bezierPath.addLine(to: CGPoint(x: -10.32, y: -2.29))
        bezierPath.addCurve(to: CGPoint(x: -12.57, y: -7.67), controlPoint1: CGPoint(x: -11.48, y: -3.84), controlPoint2: CGPoint(x: -12.57, y: -5.73))
        bezierPath.addLine(to: CGPoint(x: -12.57, y: -12.73))
        secondaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 2.23, y: -2.2))
        bezier2Path.addLine(to: CGPoint(x: -2.2, y: 3.7))
        bezier2Path.addCurve(to: CGPoint(x: -3.99, y: 9), controlPoint1: CGPoint(x: -3.36, y: 5.25), controlPoint2: CGPoint(x: -3.99, y: 7.06))
        bezier2Path.addLine(to: CGPoint(x: -3.99, y: 16))
        primaryColor.setStroke()
        bezier2Path.lineWidth = 4
        bezier2Path.lineJoinStyle = .round
        bezier2Path.stroke()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: -2.61, y: -9.17))
        bezier3Path.addLine(to: CGPoint(x: 9.54, y: -13.42))
        bezier3Path.addLine(to: CGPoint(x: 10.57, y: -0.59))
        bezier3Path.addCurve(to: CGPoint(x: 10.5, y: -0.23), controlPoint1: CGPoint(x: 10.59, y: -0.47), controlPoint2: CGPoint(x: 10.57, y: -0.34))
        bezier3Path.addCurve(to: CGPoint(x: 9.81, y: -0.08), controlPoint1: CGPoint(x: 10.35, y: 0), controlPoint2: CGPoint(x: 10.04, y: 0.07))
        bezier3Path.addCurve(to: CGPoint(x: 9.72, y: -0.15), controlPoint1: CGPoint(x: 9.77, y: -0.1), controlPoint2: CGPoint(x: 9.72, y: -0.15))
        bezier3Path.addLine(to: CGPoint(x: 6.27, y: -3.55))
        bezier3Path.addCurve(to: CGPoint(x: 6.16, y: -3.65), controlPoint1: CGPoint(x: 6.24, y: -3.59), controlPoint2: CGPoint(x: 6.2, y: -3.62))
        bezier3Path.addCurve(to: CGPoint(x: 5.35, y: -3.31), controlPoint1: CGPoint(x: 5.94, y: -3.8), controlPoint2: CGPoint(x: 5.49, y: -3.53))
        bezier3Path.addCurve(to: CGPoint(x: 3.85, y: -1), controlPoint1: CGPoint(x: 5.15, y: -3.01), controlPoint2: CGPoint(x: 3.85, y: -1))
        bezier3Path.addLine(to: CGPoint(x: 2.17, y: -2.09))
        bezier3Path.addLine(to: CGPoint(x: 0.49, y: -3.19))
        bezier3Path.addCurve(to: CGPoint(x: 1.99, y: -5.49), controlPoint1: CGPoint(x: 0.49, y: -3.19), controlPoint2: CGPoint(x: 1.8, y: -5.19))
        bezier3Path.addCurve(to: CGPoint(x: 1.91, y: -6.28), controlPoint1: CGPoint(x: 2.14, y: -5.71), controlPoint2: CGPoint(x: 2.13, y: -6.13))
        bezier3Path.addCurve(to: CGPoint(x: 1.81, y: -6.39), controlPoint1: CGPoint(x: 1.87, y: -6.3), controlPoint2: CGPoint(x: 1.85, y: -6.37))
        bezier3Path.addLine(to: CGPoint(x: -2.68, y: -8.19))
        bezier3Path.addCurve(to: CGPoint(x: -2.77, y: -8.26), controlPoint1: CGPoint(x: -2.68, y: -8.19), controlPoint2: CGPoint(x: -2.74, y: -8.23))
        bezier3Path.addCurve(to: CGPoint(x: -2.91, y: -8.95), controlPoint1: CGPoint(x: -3, y: -8.41), controlPoint2: CGPoint(x: -3.06, y: -8.72))
        bezier3Path.addCurve(to: CGPoint(x: -2.61, y: -9.17), controlPoint1: CGPoint(x: -2.84, y: -9.06), controlPoint2: CGPoint(x: -2.73, y: -9.14))
        bezier3Path.close()
        primaryColor.setFill()
        bezier3Path.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawOfframp(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), secondaryColor: UIColor = UIColor(red: 0.618, green: 0.618, blue: 0.618, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 3
        context.saveGState()
        context.translateBy(x: (x + 3.38000011444), y: y)
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -10.38, y: 16))
        bezierPath.addLine(to: CGPoint(x: -10.38, y: 7.51))
        bezierPath.addCurve(to: CGPoint(x: -10.38, y: -13), controlPoint1: CGPoint(x: -10.38, y: 5.7), controlPoint2: CGPoint(x: -10.38, y: -13))
        secondaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -0.81, y: -4.4))
        bezier2Path.addLine(to: CGPoint(x: -8.35, y: 1.79))
        bezier2Path.addCurve(to: CGPoint(x: -10.38, y: 7.17), controlPoint1: CGPoint(x: -9.51, y: 3.34), controlPoint2: CGPoint(x: -10.38, y: 5.23))
        bezier2Path.addLine(to: CGPoint(x: -10.38, y: 16))
        primaryColor.setStroke()
        bezier2Path.lineWidth = 4
        bezier2Path.lineJoinStyle = .round
        bezier2Path.stroke()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: -4.85, y: -11.35))
        bezier3Path.addLine(to: CGPoint(x: 8, y: -12.07))
        bezier3Path.addLine(to: CGPoint(x: 5.43, y: 0.55))
        bezier3Path.addCurve(to: CGPoint(x: 5.26, y: 0.87), controlPoint1: CGPoint(x: 5.42, y: 0.67), controlPoint2: CGPoint(x: 5.36, y: 0.79))
        bezier3Path.addCurve(to: CGPoint(x: 4.56, y: 0.82), controlPoint1: CGPoint(x: 5.06, y: 1.05), controlPoint2: CGPoint(x: 4.74, y: 1.03))
        bezier3Path.addCurve(to: CGPoint(x: 4.49, y: 0.73), controlPoint1: CGPoint(x: 4.53, y: 0.79), controlPoint2: CGPoint(x: 4.49, y: 0.73))
        bezier3Path.addLine(to: CGPoint(x: 2.12, y: -3.49))
        bezier3Path.addCurve(to: CGPoint(x: 2.05, y: -3.62), controlPoint1: CGPoint(x: 2.1, y: -3.54), controlPoint2: CGPoint(x: 2.08, y: -3.58))
        bezier3Path.addCurve(to: CGPoint(x: 1.17, y: -3.52), controlPoint1: CGPoint(x: 1.87, y: -3.82), controlPoint2: CGPoint(x: 1.37, y: -3.69))
        bezier3Path.addCurve(to: CGPoint(x: -0.91, y: -1.71), controlPoint1: CGPoint(x: 0.9, y: -3.28), controlPoint2: CGPoint(x: -0.91, y: -1.71))
        bezier3Path.addLine(to: CGPoint(x: -2.23, y: -3.23))
        bezier3Path.addLine(to: CGPoint(x: -3.54, y: -4.74))
        bezier3Path.addCurve(to: CGPoint(x: -1.45, y: -6.54), controlPoint1: CGPoint(x: -3.54, y: -4.74), controlPoint2: CGPoint(x: -1.72, y: -6.31))
        bezier3Path.addCurve(to: CGPoint(x: -1.32, y: -7.32), controlPoint1: CGPoint(x: -1.25, y: -6.72), controlPoint2: CGPoint(x: -1.14, y: -7.11))
        bezier3Path.addCurve(to: CGPoint(x: -1.38, y: -7.45), controlPoint1: CGPoint(x: -1.35, y: -7.36), controlPoint2: CGPoint(x: -1.34, y: -7.43))
        bezier3Path.addLine(to: CGPoint(x: -5.19, y: -10.43))
        bezier3Path.addCurve(to: CGPoint(x: -5.26, y: -10.52), controlPoint1: CGPoint(x: -5.19, y: -10.43), controlPoint2: CGPoint(x: -5.24, y: -10.49))
        bezier3Path.addCurve(to: CGPoint(x: -5.2, y: -11.23), controlPoint1: CGPoint(x: -5.44, y: -10.73), controlPoint2: CGPoint(x: -5.41, y: -11.05))
        bezier3Path.addCurve(to: CGPoint(x: -4.85, y: -11.35), controlPoint1: CGPoint(x: -5.1, y: -11.31), controlPoint2: CGPoint(x: -4.97, y: -11.36))
        bezier3Path.close()
        primaryColor.setFill()
        bezier3Path.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArriveright(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group
        context.saveGState()
        context.translateBy(x: x, y: y)
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -0.99, y: 5.6))
        bezierPath.addLine(to: CGPoint(x: -0.99, y: 16))
        primaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -3.05, y: 1.48))
        bezier2Path.addCurve(to: CGPoint(x: -3.05, y: 0.73), controlPoint1: CGPoint(x: -3.05, y: 1.48), controlPoint2: CGPoint(x: -3.05, y: 1.09))
        bezier2Path.addCurve(to: CGPoint(x: -3.55, y: 0.12), controlPoint1: CGPoint(x: -3.05, y: 0.46), controlPoint2: CGPoint(x: -3.28, y: 0.12))
        bezier2Path.addCurve(to: CGPoint(x: -3.69, y: 0.08), controlPoint1: CGPoint(x: -3.6, y: 0.12), controlPoint2: CGPoint(x: -3.65, y: 0.07))
        bezier2Path.addLine(to: CGPoint(x: -8.44, y: 1.02))
        bezier2Path.addCurve(to: CGPoint(x: -8.55, y: 1.01), controlPoint1: CGPoint(x: -8.44, y: 1.02), controlPoint2: CGPoint(x: -8.51, y: 1.01))
        bezier2Path.addCurve(to: CGPoint(x: -9.05, y: 0.51), controlPoint1: CGPoint(x: -8.83, y: 1.01), controlPoint2: CGPoint(x: -9.05, y: 0.78))
        bezier2Path.addCurve(to: CGPoint(x: -8.91, y: 0.16), controlPoint1: CGPoint(x: -9.05, y: 0.37), controlPoint2: CGPoint(x: -9, y: 0.25))
        bezier2Path.addLine(to: CGPoint(x: -1.05, y: -10.03))
        bezier2Path.addLine(to: CGPoint(x: 6.81, y: 0.16))
        bezier2Path.addCurve(to: CGPoint(x: 6.95, y: 0.5), controlPoint1: CGPoint(x: 6.9, y: 0.25), controlPoint2: CGPoint(x: 6.95, y: 0.37))
        bezier2Path.addCurve(to: CGPoint(x: 6.45, y: 1), controlPoint1: CGPoint(x: 6.95, y: 0.77), controlPoint2: CGPoint(x: 6.73, y: 1))
        bezier2Path.addCurve(to: CGPoint(x: 6.34, y: 0.99), controlPoint1: CGPoint(x: 6.41, y: 1), controlPoint2: CGPoint(x: 6.34, y: 0.99))
        bezier2Path.addLine(to: CGPoint(x: 1.59, y: 0.02))
        bezier2Path.addCurve(to: CGPoint(x: 1.45, y: -0), controlPoint1: CGPoint(x: 1.55, y: 0.01), controlPoint2: CGPoint(x: 1.5, y: -0))
        bezier2Path.addCurve(to: CGPoint(x: 0.95, y: 0.73), controlPoint1: CGPoint(x: 1.18, y: -0), controlPoint2: CGPoint(x: 0.95, y: 0.46))
        bezier2Path.addCurve(to: CGPoint(x: 0.95, y: 1.48), controlPoint1: CGPoint(x: 0.95, y: 1.09), controlPoint2: CGPoint(x: 0.95, y: 1.48))
        primaryColor.setFill()
        bezier2Path.fill()

        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 2.95, y: -15.6, width: 6.1, height: 6.1))
        primaryColor.setFill()
        ovalPath.fill()

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: -3.05, y: 2.63, width: 4, height: 1.95))
        primaryColor.setFill()
        rectanglePath.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawRoundabout(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), secondaryColor: UIColor = UIColor(red: 0.618, green: 0.618, blue: 0.618, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32), roundabout_angle: CGFloat = 90, roundabout_radius: CGFloat = 6.5) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let roundabout_arrow_height: CGFloat = scale * cos((roundabout_angle - 180) * CGFloat.pi/180) * 20
        let roundabout_arrow_width: CGFloat = scale * 0.75 * sin((roundabout_angle - 180) * CGFloat.pi/180) * 16
        let roundabout_x: CGFloat = size.width / 2.0 + roundabout_arrow_width / 2.0
        let roundabout_percentage: CGFloat = roundabout_angle / 360.0 * 2 * CGFloat.pi * roundabout_radius
        let roundabout_y: CGFloat = size.height - scale * (roundabout_radius * 2 + 4) + 1 + roundabout_arrow_height / 4.0

        //// Group 3
        context.saveGState()
        context.translateBy(x: (roundabout_x - 0.00234436950684), y: (roundabout_y - 0.995999313354))
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 6.5, y: 1))
        bezierPath.addCurve(to: CGPoint(x: 4.6, y: 5.59), controlPoint1: CGPoint(x: 6.5, y: 2.8), controlPoint2: CGPoint(x: 5.78, y: 4.42))
        bezierPath.addCurve(to: CGPoint(x: 0, y: 7.5), controlPoint1: CGPoint(x: 3.43, y: 6.77), controlPoint2: CGPoint(x: 1.8, y: 7.5))
        bezierPath.addCurve(to: CGPoint(x: -4.59, y: 5.61), controlPoint1: CGPoint(x: -1.79, y: 7.5), controlPoint2: CGPoint(x: -3.41, y: 6.78))
        bezierPath.addCurve(to: CGPoint(x: -6.5, y: 1), controlPoint1: CGPoint(x: -5.77, y: 4.43), controlPoint2: CGPoint(x: -6.5, y: 2.8))
        bezierPath.addCurve(to: CGPoint(x: -4.6, y: -3.59), controlPoint1: CGPoint(x: -6.5, y: -0.79), controlPoint2: CGPoint(x: -5.77, y: -2.42))
        bezierPath.addCurve(to: CGPoint(x: 0, y: -5.5), controlPoint1: CGPoint(x: -3.42, y: -4.77), controlPoint2: CGPoint(x: -1.79, y: -5.5))
        bezierPath.addCurve(to: CGPoint(x: 4.6, y: -3.59), controlPoint1: CGPoint(x: 1.79, y: -5.5), controlPoint2: CGPoint(x: 3.42, y: -4.77))
        bezierPath.addCurve(to: CGPoint(x: 6.5, y: 1), controlPoint1: CGPoint(x: 5.77, y: -2.42), controlPoint2: CGPoint(x: 6.5, y: -0.79))
        bezierPath.close()
        secondaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Rectangle 2 Drawing
        let rectangle2Path = UIBezierPath(roundedRect: CGRect(x: -1.97, y: 5.5, width: 4, height: 12), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 1, height: 1))
        rectangle2Path.close()
        primaryColor.setFill()
        rectangle2Path.fill()

        //// Group
        //// Bezier 2 Drawing
        context.saveGState()
        context.translateBy(x: 0, y: 1)
        context.rotate(by: -(roundabout_angle + 90) * CGFloat.pi/180)

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -9.47, y: -7.49))
        bezier2Path.addCurve(to: CGPoint(x: -9.49, y: -7.38), controlPoint1: CGPoint(x: -9.47, y: -7.45), controlPoint2: CGPoint(x: -9.49, y: -7.38))
        bezier2Path.addCurve(to: CGPoint(x: -10.45, y: -2.64), controlPoint1: CGPoint(x: -9.57, y: -6.97), controlPoint2: CGPoint(x: -10.45, y: -2.64))
        bezier2Path.addCurve(to: CGPoint(x: -10.47, y: -2.49), controlPoint1: CGPoint(x: -10.47, y: -2.59), controlPoint2: CGPoint(x: -10.47, y: -2.54))
        bezier2Path.addCurve(to: CGPoint(x: -9.82, y: -2), controlPoint1: CGPoint(x: -10.47, y: -2.25), controlPoint2: CGPoint(x: -10.09, y: -2.03))
        bezier2Path.addLine(to: CGPoint(x: -5.5, y: -2))
        bezier2Path.addCurve(to: CGPoint(x: -4.5, y: -1), controlPoint1: CGPoint(x: -4.95, y: -2), controlPoint2: CGPoint(x: -4.5, y: -1.55))
        bezier2Path.addLine(to: CGPoint(x: -4.5, y: 1))
        bezier2Path.addCurve(to: CGPoint(x: -5.5, y: 2), controlPoint1: CGPoint(x: -4.5, y: 1.55), controlPoint2: CGPoint(x: -4.95, y: 2))
        bezier2Path.addCurve(to: CGPoint(x: -9.75, y: 2.01), controlPoint1: CGPoint(x: -5.5, y: 2), controlPoint2: CGPoint(x: -9.38, y: 2.01))
        bezier2Path.addCurve(to: CGPoint(x: -10.35, y: 2.51), controlPoint1: CGPoint(x: -10.01, y: 2.01), controlPoint2: CGPoint(x: -10.35, y: 2.24))
        bezier2Path.addCurve(to: CGPoint(x: -10.39, y: 2.65), controlPoint1: CGPoint(x: -10.35, y: 2.56), controlPoint2: CGPoint(x: -10.41, y: 2.6))
        bezier2Path.addLine(to: CGPoint(x: -9.46, y: 7.39))
        bezier2Path.addCurve(to: CGPoint(x: -9.46, y: 7.51), controlPoint1: CGPoint(x: -9.46, y: 7.39), controlPoint2: CGPoint(x: -9.46, y: 7.47))
        bezier2Path.addCurve(to: CGPoint(x: -9.97, y: 8.01), controlPoint1: CGPoint(x: -9.46, y: 7.78), controlPoint2: CGPoint(x: -9.69, y: 8.01))
        bezier2Path.addCurve(to: CGPoint(x: -10.31, y: 7.87), controlPoint1: CGPoint(x: -10.1, y: 8.01), controlPoint2: CGPoint(x: -10.22, y: 7.95))
        bezier2Path.addLine(to: CGPoint(x: -20.5, y: 0.01))
        bezier2Path.addLine(to: CGPoint(x: -10.31, y: -7.86))
        bezier2Path.addCurve(to: CGPoint(x: -9.97, y: -7.99), controlPoint1: CGPoint(x: -10.22, y: -7.94), controlPoint2: CGPoint(x: -10.11, y: -7.99))
        bezier2Path.addCurve(to: CGPoint(x: -9.47, y: -7.49), controlPoint1: CGPoint(x: -9.7, y: -7.99), controlPoint2: CGPoint(x: -9.47, y: -7.77))
        bezier2Path.close()
        primaryColor.setFill()
        bezier2Path.fill()

        context.restoreGState()

        //// Bezier 3 Drawing
        context.saveGState()
        context.translateBy(x: 1, y: 2)
        context.rotate(by: -90 * CGFloat.pi/180)
        context.scaleBy(x: -1, y: 1)

        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 5.5, y: -1))
        bezier3Path.addCurve(to: CGPoint(x: 3.6, y: 3.59), controlPoint1: CGPoint(x: 5.5, y: 0.79), controlPoint2: CGPoint(x: 4.78, y: 2.41))
        bezier3Path.addCurve(to: CGPoint(x: -1, y: 5.5), controlPoint1: CGPoint(x: 2.43, y: 4.77), controlPoint2: CGPoint(x: 0.8, y: 5.5))
        bezier3Path.addCurve(to: CGPoint(x: -5.59, y: 3.61), controlPoint1: CGPoint(x: -2.79, y: 5.5), controlPoint2: CGPoint(x: -4.41, y: 4.78))
        bezier3Path.addCurve(to: CGPoint(x: -7.5, y: -1), controlPoint1: CGPoint(x: -6.77, y: 2.43), controlPoint2: CGPoint(x: -7.5, y: 0.8))
        bezier3Path.addCurve(to: CGPoint(x: -5.6, y: -5.6), controlPoint1: CGPoint(x: -7.5, y: -2.79), controlPoint2: CGPoint(x: -6.77, y: -4.42))
        bezier3Path.addCurve(to: CGPoint(x: -1, y: -7.5), controlPoint1: CGPoint(x: -4.42, y: -6.77), controlPoint2: CGPoint(x: -2.79, y: -7.5))
        bezier3Path.addCurve(to: CGPoint(x: 3.6, y: -5.6), controlPoint1: CGPoint(x: 0.79, y: -7.5), controlPoint2: CGPoint(x: 2.42, y: -6.77))
        bezier3Path.addCurve(to: CGPoint(x: 5.5, y: -1), controlPoint1: CGPoint(x: 4.77, y: -4.42), controlPoint2: CGPoint(x: 5.5, y: -2.79))
        bezier3Path.close()
        primaryColor.setStroke()
        bezier3Path.lineWidth = 4
        bezier3Path.lineJoinStyle = .round
        context.saveGState()
        context.setLineDash(phase: 0, lengths: [roundabout_percentage, 1000])
        bezier3Path.stroke()
        context.restoreGState()

        context.restoreGState()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc dynamic public class func drawArriveright2(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 32, height: 32), resizing: ResizingBehavior = .aspectFit, primaryColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), size: CGSize = CGSize(width: 32, height: 32)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 32, height: 32), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 32, y: resizedFrame.height / 32)

        //// Variable Declarations
        let scale: CGFloat = min(size.width / 32.0, size.height / 32.0)
        let x: CGFloat = size.width / 2.0
        let y: CGFloat = size.height / 2.0

        //// Group 2
        context.saveGState()
        context.translateBy(x: x, y: y)
        context.scaleBy(x: scale, y: scale)

        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0.06, y: 6.6))
        bezierPath.addLine(to: CGPoint(x: 0.06, y: 16))
        primaryColor.setStroke()
        bezierPath.lineWidth = 4
        bezierPath.lineJoinStyle = .round
        bezierPath.stroke()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: -2, y: 2.48))
        bezier2Path.addCurve(to: CGPoint(x: -2, y: 1.73), controlPoint1: CGPoint(x: -2, y: 2.48), controlPoint2: CGPoint(x: -2, y: 2.09))
        bezier2Path.addCurve(to: CGPoint(x: -2.5, y: 1.12), controlPoint1: CGPoint(x: -2, y: 1.46), controlPoint2: CGPoint(x: -2.23, y: 1.12))
        bezier2Path.addCurve(to: CGPoint(x: -2.64, y: 1.08), controlPoint1: CGPoint(x: -2.55, y: 1.12), controlPoint2: CGPoint(x: -2.6, y: 1.07))
        bezier2Path.addLine(to: CGPoint(x: -7.39, y: 2.02))
        bezier2Path.addCurve(to: CGPoint(x: -7.5, y: 2.01), controlPoint1: CGPoint(x: -7.39, y: 2.02), controlPoint2: CGPoint(x: -7.46, y: 2.01))
        bezier2Path.addCurve(to: CGPoint(x: -8, y: 1.51), controlPoint1: CGPoint(x: -7.78, y: 2.01), controlPoint2: CGPoint(x: -8, y: 1.78))
        bezier2Path.addCurve(to: CGPoint(x: -7.86, y: 1.16), controlPoint1: CGPoint(x: -8, y: 1.37), controlPoint2: CGPoint(x: -7.95, y: 1.25))
        bezier2Path.addLine(to: CGPoint(x: 0, y: -9.03))
        bezier2Path.addLine(to: CGPoint(x: 7.86, y: 1.16))
        bezier2Path.addCurve(to: CGPoint(x: 8, y: 1.5), controlPoint1: CGPoint(x: 7.95, y: 1.25), controlPoint2: CGPoint(x: 8, y: 1.37))
        bezier2Path.addCurve(to: CGPoint(x: 7.5, y: 2), controlPoint1: CGPoint(x: 8, y: 1.77), controlPoint2: CGPoint(x: 7.78, y: 2))
        bezier2Path.addCurve(to: CGPoint(x: 7.39, y: 1.99), controlPoint1: CGPoint(x: 7.46, y: 2), controlPoint2: CGPoint(x: 7.39, y: 1.99))
        bezier2Path.addLine(to: CGPoint(x: 2.64, y: 1.02))
        bezier2Path.addCurve(to: CGPoint(x: 2.5, y: 1), controlPoint1: CGPoint(x: 2.6, y: 1.01), controlPoint2: CGPoint(x: 2.55, y: 1))
        bezier2Path.addCurve(to: CGPoint(x: 2, y: 1.73), controlPoint1: CGPoint(x: 2.23, y: 1), controlPoint2: CGPoint(x: 2, y: 1.46))
        bezier2Path.addCurve(to: CGPoint(x: 2, y: 2.48), controlPoint1: CGPoint(x: 2, y: 2.09), controlPoint2: CGPoint(x: 2, y: 2.48))
        primaryColor.setFill()
        bezier2Path.fill()

        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: -2, y: 3.62, width: 4, height: 1.95))
        primaryColor.setFill()
        rectanglePath.fill()

        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 6, y: -13.69))
        bezier3Path.addCurve(to: CGPoint(x: 5.64, y: -13.63), controlPoint1: CGPoint(x: 5.87, y: -13.69), controlPoint2: CGPoint(x: 5.75, y: -13.67))
        bezier3Path.addCurve(to: CGPoint(x: 4.88, y: -12.57), controlPoint1: CGPoint(x: 5.19, y: -13.48), controlPoint2: CGPoint(x: 4.88, y: -13.06))
        bezier3Path.addCurve(to: CGPoint(x: 6, y: -11.44), controlPoint1: CGPoint(x: 4.88, y: -11.95), controlPoint2: CGPoint(x: 5.38, y: -11.44))
        bezier3Path.addCurve(to: CGPoint(x: 7.13, y: -12.57), controlPoint1: CGPoint(x: 6.62, y: -11.44), controlPoint2: CGPoint(x: 7.13, y: -11.95))
        bezier3Path.addCurve(to: CGPoint(x: 6, y: -13.69), controlPoint1: CGPoint(x: 7.13, y: -13.19), controlPoint2: CGPoint(x: 6.62, y: -13.69))
        bezier3Path.close()
        bezier3Path.move(to: CGPoint(x: 9, y: -12.57))
        bezier3Path.addCurve(to: CGPoint(x: 6, y: -6.57), controlPoint1: CGPoint(x: 9, y: -10.91), controlPoint2: CGPoint(x: 7.5, y: -9.94))
        bezier3Path.addCurve(to: CGPoint(x: 3, y: -12.57), controlPoint1: CGPoint(x: 4.5, y: -9.94), controlPoint2: CGPoint(x: 3, y: -10.91))
        bezier3Path.addCurve(to: CGPoint(x: 4, y: -14.8), controlPoint1: CGPoint(x: 3, y: -13.45), controlPoint2: CGPoint(x: 3.38, y: -14.25))
        bezier3Path.addCurve(to: CGPoint(x: 4.64, y: -15.24), controlPoint1: CGPoint(x: 4.19, y: -14.97), controlPoint2: CGPoint(x: 4.41, y: -15.12))
        bezier3Path.addCurve(to: CGPoint(x: 6, y: -15.57), controlPoint1: CGPoint(x: 5.05, y: -15.45), controlPoint2: CGPoint(x: 5.51, y: -15.57))
        bezier3Path.addCurve(to: CGPoint(x: 9, y: -12.57), controlPoint1: CGPoint(x: 7.66, y: -15.57), controlPoint2: CGPoint(x: 9, y: -14.22))
        bezier3Path.close()
        primaryColor.setFill()
        bezier3Path.fill()

        context.restoreGState()
        
        context.restoreGState()

    }

    @objc(MBManeuversStyleKitResizingBehavior)
    public enum ResizingBehavior: Int {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
                case .aspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .aspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .stretch:
                    break
                case .center:
                    scales.width = 1
                    scales.height = 1
            }

            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }
}
