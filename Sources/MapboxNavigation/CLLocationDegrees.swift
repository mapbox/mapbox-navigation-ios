import CoreLocation

extension CLLocationDegrees {
    
    /**
     Returns Earth's radius for specific latitude.
     */
    var radius: Double {
        let sinVal = sin(self * .pi / 180)
        let radX2 = log((1 + sinVal) / (1 - sinVal)) / 2
        return max(min(radX2, .pi), -.pi) / 2
    }
}
