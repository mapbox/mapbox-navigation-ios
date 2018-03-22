import Foundation

extension NavigationCamera {
    
    typealias CompletionHandler = ((Bool) -> Void)?
    
    func setCourseTracking(centerCoordinate: CLLocationCoordinate2D, direction: CLLocationDirection, pitch: CGFloat, altitude: CLLocationDistance, animated: Bool, completion: CompletionHandler = nil) {
        
        guard !isTransitioning else {
            completion?(false)
            return
        }
        
        UIView.animate(withDuration: 1, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            self.centerCoordinate = centerCoordinate
            self.direction = direction
            self.pitch = pitch
            self.altitude = altitude
        }, completion: completion)
    }
    
    func transitionToCourseTracking(duration: TimeInterval = 2,
                                    centerCoordinate: CLLocationCoordinate2D,
                                    direction: CLLocationDirection,
                                    pitch: CGFloat,
                                    altitude: CLLocationDistance,
                                    completion: CompletionHandler = nil) {
        guard !isTransitioning else {
            completion?(false)
            return
        }
        
        isTransitioning = true
        
        UIView.animate(withDuration: 0.2 * duration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.centerCoordinate = centerCoordinate
        }, completion: nil)
        
        UIView.animate(withDuration: 0.8 * duration, delay: 0.2 * duration, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.altitude = altitude
        }, completion: nil)
        
        UIView.animate(withDuration: 0.2 * duration, delay: 0.8 * duration, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.pitch = pitch
        }) { (successfully) in
            self.isTransitioning = false
            completion?(successfully)
        }
        
        UIView.animate(withDuration: 0.5 * duration, delay: 0.2 * duration, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.direction = direction
        }, completion: nil)
    }
    
    func transitionToOverview(duration: TimeInterval = 1, altitude: CLLocationDistance, pitch: CGFloat, direction: CLLocationDirection, completion: CompletionHandler = nil) {
        guard !isTransitioning else {
            completion?(false)
            return
        }
        
        isTransitioning = true
        
        UIView.animate(withDuration: 0.2 * duration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.pitch = pitch
        }, completion: nil)
        
        UIView.animate(withDuration: 0.8 * duration, delay: 0.2 * duration, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.altitude = altitude
        }, completion: nil)
        
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.direction = direction
        }) { (successfully) in
            self.isTransitioning = false
            completion?(successfully)
        }
    }
}
