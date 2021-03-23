import CoreLocation

extension CLLocationDirection {
    
    /**
     Returns shortest rotation between two angles.
     */
    func shortestRotation(angle: CLLocationDirection) -> CLLocationDirection {
        guard !self.isNaN && !angle.isNaN else { return 0.0 }
        return (self - angle).wrap(min: -180.0, max: 180.0)
    }
}
