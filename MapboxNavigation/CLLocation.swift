import CoreLocation

extension CLLocation {
    var debugInformation: String {
        var info = ""
        info += "Speed: \(speed)"
        info += "\nCourse: \(course)"
        info += "\nHA: \(horizontalAccuracy)"
        info += "\nVA: \(verticalAccuracy)"
        return info
    }
}
