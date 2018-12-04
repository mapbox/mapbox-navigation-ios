import UIKit


class ResizableView: UIControl {
    
    let lineLayer = CAShapeLayer()
    // Associated background layer will be masked by the frame of the resizable view
    weak var backgroundLayer: CAShapeLayer?
    let maskLayer = CAShapeLayer()
    var imageView: UIImageView!
    var panRecognizer: UIPanGestureRecognizer!
    var resizePanRecognizer: UIPanGestureRecognizer!
    
    convenience init(frame: CGRect, backgroundLayer: CAShapeLayer) {
        self.init(frame: frame)
        self.backgroundLayer = backgroundLayer
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        clipsToBounds = false
        layer.masksToBounds = false
        isUserInteractionEnabled = true
        backgroundColor = .clear
        isOpaque = false
        layer.backgroundColor = UIColor.clear.cgColor
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        resizePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(resizePan(_:)))
        
        let image = UIImage(named: "ic_resize")!.withPadding(x: 12, y: 12)!
        imageView = UIImageView(image: image.withRenderingMode(.alwaysTemplate))
        imageView.layer.cornerRadius = image.size.width.mid
        imageView.backgroundColor = .white
        imageView.tintColor = #colorLiteral(red: 0, green: 0.5490196078, blue: 1, alpha: 1)
        imageView.isUserInteractionEnabled = true
        imageView.layer.shadowColor = #colorLiteral(red: 0.1029271765, green: 0.08949588804, blue: 0.1094761982, alpha: 0.8005611796)
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.layer.shadowOpacity = 1
        imageView.layer.shadowRadius = 1.0
        
        panRecognizer.require(toFail: resizePanRecognizer)
        
        addGestureRecognizer(panRecognizer)
        imageView.addGestureRecognizer(resizePanRecognizer)
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            center = sender.location(in: superview)
            
            layoutSubviews()
        }
    }
    
    @objc func resizePan(_ sender: UIPanGestureRecognizer) {
        
        let location = sender.location(in: superview)
        
        if sender.state == .began || sender.state == .changed {
            
            let origin = CGPoint(x: frame.minX, y: frame.minY)
            frame = CGRect(origin: origin,
                           size: CGSize(width: location.x - origin.x,
                                        height: location.y - origin.y))
            layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if lineLayer.superlayer == nil {
            lineLayer.strokeColor = #colorLiteral(red: 0, green: 0.5490196078, blue: 1, alpha: 1).cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            lineLayer.lineWidth = 1
            lineLayer.lineDashPattern = [5, 5]
            layer.addSublayer(lineLayer)
        }
        
        lineLayer.path = UIBezierPath(rect: bounds).cgPath
        
        let clippedPath = UIBezierPath(rect: superview!.bounds)
        clippedPath.append(UIBezierPath(rect: lineLayer.frame))
        
        let superFrame = self.convert(superview!.bounds, to: self)
        
        if let backgroundLayer = backgroundLayer {
            backgroundLayer.path = UIBezierPath(rect: superFrame).cgPath
            backgroundLayer.frame = superFrame
            
            let path = UIBezierPath(rect: frame)
            path.append(UIBezierPath(rect: backgroundLayer.bounds))
            
            maskLayer.fillRule = kCAFillRuleEvenOdd
            maskLayer.path = path.cgPath
            backgroundLayer.mask = maskLayer
        }
        
        imageView.center = CGPoint(x: bounds.maxX-5, y: bounds.maxY-5)
        
        bringSubview(toFront: imageView)
    }
    
}

fileprivate extension CGFloat {
    
    var mid: CGFloat {
        return self / 2
    }
}

extension UIImage {
    
    func withPadding(x: CGFloat, y: CGFloat) -> UIImage? {
        let width: CGFloat = size.width + x
        let height: CGFloat = size.height + y
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        let origin: CGPoint = CGPoint(x: (width - size.width) / 2, y: (height - size.height) / 2)
        draw(at: origin)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
