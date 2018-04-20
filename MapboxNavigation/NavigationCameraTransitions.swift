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
    
    func updateAltitude(_ altitude: CLLocationDistance, completion: CompletionHandler = nil) {
        UIView.animate(withDuration: 1, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
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
        
        // The following animations will transition to course tracking mode by running four animations in parallel.
        // Starting by moving the center coordinate, quickly followed by adjusting the altitude and rotating the map, finished off by changing the pitch.
        
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
    
    func transitionToOverview(duration: TimeInterval = 1,
                              coordinates: [CLLocationCoordinate2D],
                              edgePadding: UIEdgeInsets,
                              completion: CompletionHandler = nil) {
        
        
        guard !isTransitioning else {
            completion?(false)
            return
        }
        
        let line = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        
        // The following animations will transition to overview mode.
        // Starting by resetting the pitch, followed by moving the center coordinate, reset to north, and fit to coordinates.
        
        UIView.animate(withDuration: 0.2 * duration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.pitch = 0
        }) { (success) in
            let camera = self.mapView.cameraThatFitsShape(line, direction: 0, edgePadding: edgePadding)
            
            UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
                self.centerCoordinate = camera.centerCoordinate
                self.direction = 0
                self.altitude = camera.altitude
            }, completion: { (success) in
                completion?(success)
            })
        }
    }
}
