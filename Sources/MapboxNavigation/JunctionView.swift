import UIKit
import MapboxCoreNavigation
import MapboxDirections

/**
 A junction view shows an image depicting the layout of a highway junction.
 
 As the user approaches certain junctions, an enlarged illustration of the junction appears in this view to help the user understand a complex maneuver. A junction view only appears when the relevant data is available.
 */
public class JunctionView: UIImageView {
    
    // MARK: Displaying the Junction
    
    /**
     Shows the junction view, optionally with a fade animation.
     */
    public func show(animated: Bool = false) {
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
                show(animated: true)
            } else {
                guard let imageURL = guidanceViewImageRepresentation.imageURL else { return }
                let baseURLString = imageURL.absoluteString
                guard let accessToken = service.credentials.accessToken else { return }
                let stringURL = baseURLString + "&access_token=" + accessToken

                guard let guidanceViewImageURL = URL(string: stringURL) else { return }
                imageRepository.imageWithURL(guidanceViewImageURL, cacheKey: guidanceView.cacheKey!) { [weak self] (downloadedImage) in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        
                        self.isCurrentlyVisible = true
                        self.isHidden = !self.isCurrentlyVisible
                        
                        self.image = downloadedImage
                        self.show(animated: true)
                    }
                }
            }
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
}
