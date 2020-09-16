import UIKit

class DelayInformationView: UIView {
    
    override func draw(_ rect: CGRect) {
        let lineWidth: CGFloat = 2
        let cornerRadius: CGFloat = 3
        let tipLength: CGFloat = 6
        let fillColor: UIColor = .red
        let strokeColor: UIColor = .black
        
        let rect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - tipLength))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - tipLength - cornerRadius), controlPoint: CGPoint(x: rect.minX, y: rect.maxY - tipLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY), controlPoint: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius), controlPoint: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tipLength - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - tipLength), controlPoint: CGPoint(x: rect.maxX, y: rect.maxY - tipLength))
        path.addLine(to: CGPoint(x: rect.midX + tipLength, y: rect.maxY - tipLength))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - tipLength, y: rect.maxY - tipLength))
        path.close()
        
        fillColor.setFill()
        path.fill()
        
        strokeColor.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}
