import UIKit


class ResizableView: UIControl {
    
    let lineLayer = CAShapeLayer()
    var imageView: UIImageView!
    var panRecognizer: UIPanGestureRecognizer!
    var resizePanRecognizer: UIPanGestureRecognizer!
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        clipsToBounds = false
        isUserInteractionEnabled = true
        backgroundColor = .clear
        isOpaque = false
        layer.backgroundColor = UIColor.clear.cgColor
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        resizePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(resizePan(_:)))
        
        let image = UIImage(named: "resize-filter")!.withRenderingMode(.alwaysTemplate)
        imageView = UIImageView(image: image)
        imageView.tintColor = .lightGray
        imageView.isUserInteractionEnabled = true
        
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
        }
    }
    
    @objc func resizePan(_ sender: UIPanGestureRecognizer) {
        
        let location = sender.location(in: superview)
        
        if sender.state == .began || sender.state == .changed {
            
            let origin = CGPoint(x: frame.minX, y: frame.minY)
            frame = CGRect(origin: origin,
                           size: CGSize(width: location.x.distance(origin.x),
                                        height: location.y.distance(origin.y)))
            layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if lineLayer.superlayer == nil {
            lineLayer.strokeColor = UIColor.gray.cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            lineLayer.lineWidth = 3
            lineLayer.lineDashPattern = [4, 2]
            layer.addSublayer(lineLayer)
        }
        
        lineLayer.path = UIBezierPath(rect: bounds).cgPath
        imageView.center = CGPoint(x: bounds.maxX - imageView.image!.size.width.mid,
                                   y: bounds.maxY - imageView.image!.size.height.mid)
        bringSubview(toFront: imageView)
    }
    
}

fileprivate extension CGFloat {
    
    var mid: CGFloat {
        return self / 2
    }
    
    func distance(_ to: CGFloat) -> CGFloat {
        return self - to
    }
}
