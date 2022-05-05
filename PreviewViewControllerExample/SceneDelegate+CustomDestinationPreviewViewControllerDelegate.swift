import Foundation
import MapboxCoreNavigation
import MapboxDirections
@_spi(Experimental) import MapboxNavigation

extension SceneDelegate: CustomDestinationPreviewViewControllerDelegate {
    
    func didPressDirectionsButton() {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured: \(error.localizedDescription).")
            case .success(let routeResponse):
                guard let self = self else { return }
                
                self.routeResponse = routeResponse
                self.previewViewController.preview(routeResponse)
            }
        }
    }
}
