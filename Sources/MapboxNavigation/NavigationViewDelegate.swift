import Foundation

protocol NavigationViewDelegate: NavigationMapViewDelegate, InstructionsBannerViewDelegate {
    
    func navigationView(_ navigationView: NavigationView, didTap cancelButton: CancelButton)
    
    func navigationView(_ navigationView: NavigationView, didReplace navigationMapView: NavigationMapView)
}
