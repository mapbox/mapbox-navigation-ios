import Foundation
import CoreGraphics
import CoreLocation

private let tileSize: Double = 512.0
private let M2PI = Double.pi * 2
private let MPI2 = Double.pi / 2
private let DEG2RAD = Double.pi / 180.0
private let EARTH_RADIUS_M = 6378137.0
private let LATITUDE_MAX: Double = 85.051128779806604
private let AngularFieldOfView: CLLocationDegrees = 30
private let MIN_ZOOM = 0.0
private let MAX_ZOOM = 25.5

func AltitudeForZoomLevel(_ zoomLevel: Double, _ pitch: CGFloat, _ latitude: CLLocationDegrees, _ size: CGSize) -> CLLocationDistance {
    let metersPerPixel = getMetersPerPixelAtLatitude(latitude, zoomLevel)
    let metersTall = metersPerPixel * Double(size.height)
    let altitude = metersTall / 2 / tan(RadiansFromDegrees(AngularFieldOfView) / 2)
    return altitude * sin(MPI2 - RadiansFromDegrees(CLLocationDegrees(pitch))) / sin(MPI2)
}

func ZoomLevelForAltitude(_ altitude: CLLocationDistance, _ pitch: CGFloat, _ latitude: CLLocationDegrees, _ size: CGSize) -> Double {
    let eyeAltitude = altitude / sin(MPI2 - RadiansFromDegrees(CLLocationDegrees(pitch))) * sin(MPI2)
    let metersTall = eyeAltitude * 2 * tan(RadiansFromDegrees(AngularFieldOfView) / 2)
    let metersPerPixel = metersTall / Double(size.height)
    let mapPixelWidthAtZoom = cos(RadiansFromDegrees(latitude)) * M2PI * EARTH_RADIUS_M / metersPerPixel
    return log2(mapPixelWidthAtZoom / tileSize)
}

private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
    return fmax(min, fmin(max, value))
}

private func worldSize(_ scale: Double) -> Double {
    return scale * tileSize
}

private func RadiansFromDegrees(_ degrees: CLLocationDegrees) -> Double {
    return degrees * Double.pi / 180
}

func getMetersPerPixelAtLatitude(_ lat: Double, _ zoom: Double) -> Double {
    let constrainedZoom = clamp(zoom, MIN_ZOOM, MAX_ZOOM)
    let constrainedScale = pow(2.0, constrainedZoom)
    let constrainedLatitude = clamp(lat, -LATITUDE_MAX, LATITUDE_MAX)
    return cos(constrainedLatitude * DEG2RAD) * M2PI * EARTH_RADIUS_M / worldSize(constrainedScale)
}

