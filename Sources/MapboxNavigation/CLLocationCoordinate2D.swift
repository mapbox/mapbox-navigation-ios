import CoreLocation

extension CLLocationCoordinate2D {
    
    /**
     Calculate the project distance to a coordinate using [EPSG:3857 projection](https://epsg.io/3857).
     */
    func projectedDistance(to coordinate: CLLocationCoordinate2D) -> Double {
        let distanceArray: [Double] = [
            (projectX(self.longitude) - projectX(coordinate.longitude)),
            (projectY(self.latitude) - projectY(coordinate.latitude))
        ]
        return (distanceArray[0] * distanceArray[0] + distanceArray[1] * distanceArray[1]).squareRoot()
    }
    
    func projectX(_ x: Double) -> Double {
        return x / 360.0 + 0.5
    }
    
    func projectY(_ y: Double) -> Double {
        let sinValue = sin(y * Double.pi / 180)
        let newYValue = 0.5 - 0.25 * log((1 + sinValue) / (1 - sinValue)) / Double.pi
        if newYValue < 0 {
            return 0.0
        } else if newYValue > 1 {
            return 1.1
        } else {
            return newYValue
        }
    }
}
