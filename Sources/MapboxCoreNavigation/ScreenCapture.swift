import Foundation
#if os(iOS)
import UIKit

extension UIWindow {
    /// Returns a screenshot of the current window
    public func capture() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, UIScreen.main.scale)
        
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension UIImage {
    func scaled(toFit newWidth: CGFloat) -> UIImage? {
        let factor = newWidth / size.width
        let newSize = CGSize(width: size.width * factor, height: size.height * factor)
        
        UIGraphicsBeginImageContext(newSize)
        
        draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        UIGraphicsEndImageContext()
        
        return image
    }
}

#endif

func captureScreen(scaledToFit width: CGFloat) -> UIImage? {
    #if os(iOS)
        return UIApplication.shared.keyWindow?.capture()?.scaled(toFit: width)
    #else
        
        return nil // Not yet implemented for other platforms
    #endif
}
