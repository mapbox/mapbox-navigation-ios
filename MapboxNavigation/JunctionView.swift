import UIKit
import MapboxCoreNavigation
import MapboxDirections


/// :nodoc:
public class JunctionView: UIImageView {
    var isCurrentlyVisible: Bool = false
    var imageRepository: ImageRepository = .shared
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
    }
    
    /**
     Updates the quaternary guidance view  banner image with a given `VisualInstructionBanner`.
     */
    public func update(for visualInstruction: VisualInstructionBanner?, service: NavigationService) {
        let quaternaryInstruction = visualInstruction?.quaternaryInstruction
        
        if quaternaryInstruction == nil {
            hide(delay: 10, animated: true)
        }
        
        guard let guidanceView = quaternaryInstruction?.components.first else { return }
        
        if case .guidanceView(let guidanceViewImageRepresentation, _) = guidanceView {
            if let cachedImage = imageRepository.cachedImageForKey(guidanceView.cacheKey!) {
                image = cachedImage
                show(true)
            } else {
                guard let imageURL = guidanceViewImageRepresentation.imageURL else { return }
                let baseURLString = imageURL.absoluteString
                guard let accessToken = service.directions.credentials.accessToken else { return }
                let stringURL = baseURLString + "&access_token=" + accessToken

                guard let guidanceViewImageURL = URL(string: stringURL) else { return }
                imageRepository.imageWithURL(guidanceViewImageURL, cacheKey: guidanceView.cacheKey!) { [unowned self] (downloadedImage) in
                    
                    self.isCurrentlyVisible = true
                    self.isHidden = !self.isCurrentlyVisible
                    
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                        self.show(true)
                    }
                }
            }
        }
        
    }
    
    /**
     Shows the junction view with.
     */
    public func show(_ animated: Bool = false) {
        guard !isCurrentlyVisible, isHidden else { return }
        
        let show = {
            self.isHidden = false
            if let height = self.image?.size.height {
                let heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
                heightConstraint.priority = UILayoutPriority(rawValue: 999)
                heightConstraint.isActive = true
            }
            
        }
        
        let animate = {
            show()
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
                self.layoutIfNeeded()
            }) { [weak self] (finished) in
                self?.isCurrentlyVisible = true
            }
        }

        if animated {
            animate()
        } else {
            show()
            isCurrentlyVisible = true
        }
         
    }
    
    /**
     Hides the junction view.
     */
    public func hide(delay: TimeInterval = 0, animated: Bool = true) {
        guard !self.isHidden, self.isCurrentlyVisible else { return }
        
        let hide = {
            let heightConstraint = self.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = UILayoutPriority(rawValue: 999)
            heightConstraint.isActive = true
        }
        
        let animate = {
            hide()
            let fireTime = DispatchTime.now() + delay
            DispatchQueue.main.asyncAfter(deadline: fireTime, execute: {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                    self.layoutIfNeeded()
                }) { [weak self] (finished) in
                    self?.isCurrentlyVisible = false
                    self?.isHidden = true
                }
            })
        }
        
        if animated {
            animate()
        } else {
            hide()
            isCurrentlyVisible = false
            isHidden = true
        }
    }
}
