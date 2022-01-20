import Foundation

protocol NavigationViewDelegate: NavigationMapViewDelegate, InstructionsBannerViewDelegate {
    
    func navigationView(_ view: NavigationView, didTapCancelButton: CancelButton)
}
