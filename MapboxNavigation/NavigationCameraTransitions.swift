import Foundation

extension NavigationCamera {
    
    func setCourseFollowing(centerCoordinate: CLLocationCoordinate2D, course: CLLocationDirection, pitch: CGFloat, altitude: CLLocationDistance, animated: Bool) {
        updateValues()
        
        UIView.animate(withDuration: 1, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            self.centerCoordinate = centerCoordinate
            self.course = course
            self.pitch = pitch
            self.altitude = altitude
        }, completion: nil)
    }
    
    func transitionFromOverview(centerCoordinate: CLLocationCoordinate2D, course: CLLocationDirection, pitch: CGFloat, altitude: CLLocationDistance) {
        
        UIView.animate(withDuration: 1) {
            self.altitude = altitude
        }
        
        UIView.animate(withDuration: 1) {
            self.altitude = altitude
        }
        
        UIView.animate(withDuration: 1, delay: 1, options: [], animations: {
            self.pitch = pitch
        }, completion: nil)
        
        UIView.animate(withDuration: 1, delay: 2, options: [], animations: {
            self.course = course
        }, completion: nil)
    }
    
    func setOverview(altitude: CLLocationDistance, pitch: CGFloat, course: CLLocationDirection) {
        updateValues()
        
        UIView.animate(withDuration: 1) {
            self.altitude = altitude
        }
        UIView.animate(withDuration: 1, delay: 1, options: [], animations: {
            self.pitch = pitch
        }, completion: nil)
        UIView.animate(withDuration: 1, delay: 2, options: [], animations: {
            self.course = course
        }, completion: nil)
    }
    
}
