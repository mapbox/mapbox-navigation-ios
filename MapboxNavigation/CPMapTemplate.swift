import Foundation
import MapboxDirections
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
extension CLLocationDirection {
    init?(panDirection: CPMapTemplate.PanDirection) {
        var horizontalBias: Double? = nil
        if panDirection.contains(.right) {
            horizontalBias = 90
        } else if panDirection.contains(.left) {
            horizontalBias = -90
        }
        
        var heading: CLLocationDirection
        if panDirection.contains(.up) {
            heading = 0
            if let horizontalHeading = horizontalBias {
                heading += horizontalHeading / 2
            }
        } else if panDirection.contains(.down) {
            heading = 180
            if let horizontalHeading = horizontalBias {
                heading -= horizontalHeading / 2
            }
        } else if let horizontalHeading = horizontalBias {
            heading = horizontalHeading
        } else {
            return nil
        }
        self = heading.wrap(min: 0, max: 360)
    }
}

extension UIViewController {
    
    func carPlayContentInsets(forOverviewing overviewing: Bool) -> UIEdgeInsets {
        var contentInsets = view.safeArea
        
        if overviewing {
            //let routeLineWidths = MBRouteLineWidthByZoomLevel.compactMap { $0.value.constantValue as? Int }
            //contentInsets += UIEdgeInsets(floatLiteral: Double(routeLineWidths.max() ?? 0))
            contentInsets += NavigationMapView.courseViewMinimumInsets
        }
        
        return contentInsets
    }
}

#endif

