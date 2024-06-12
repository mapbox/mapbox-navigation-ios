import Foundation
import MapboxNavigationCore

protocol NavigationViewDelegate: /* NavigationMapViewDelegate, */ InstructionsBannerViewDelegate {
    func navigationView(_ navigationView: NavigationView, didTap cancelButton: CancelButton)

    func navigationView(_ navigationView: NavigationView, didReplace navigationMapView: NavigationMapView)
}
