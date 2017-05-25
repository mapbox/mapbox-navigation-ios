import Foundation
import MapboxCoreNavigation

class DebugAnnotation: MGLPointAnnotation {
    var color: UIColor = .red
}
class DebugAnnotationView: MGLAnnotationView {}

extension RouteMapViewController {
    func addDebugAnnotation(location: CLLocation) {
        let annotation = DebugAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "Reroute"
        annotation.color = .red
        let newLocation = location.advanced(by: RouteControllerDeadReckoningTimeInterval)
        let radius = location.rerouteRadius
        
        var subtitle = location.debugInformation
        
        subtitle += "\nMeters in front of user: \(location.distance(from: newLocation))"
        subtitle += "\nRadius: \(radius)"
        annotation.subtitle = subtitle
        
        let annotationInFrontOfUser = DebugAnnotation()
        annotationInFrontOfUser.coordinate = newLocation.coordinate
        annotationInFrontOfUser.title = "Dead reckoning"
        annotationInFrontOfUser.subtitle = newLocation.debugInformation
        annotationInFrontOfUser.color = .blue
        mapView?.addAnnotation(annotation)
        mapView?.addAnnotation(annotationInFrontOfUser)
        
        guard let closestCoordinate = closestCoordinate(on: routeController.routeProgress.currentLegProgress.currentStep.coordinates!, to: newLocation.coordinate) else {
            return
        }
        
        let closestAnnotation = DebugAnnotation()
        closestAnnotation.coordinate = closestCoordinate.coordinate
        closestAnnotation.title = "Closest coordinate"
        closestAnnotation.subtitle = "Distance: \(closestCoordinate.distance)"
        closestAnnotation.color = .green
        mapView?.addAnnotation(closestAnnotation)
    }
    
    func showDebugAlert(with annotation: DebugAnnotation) {
        let controller = UIAlertController(title: annotation.title, message: annotation.subtitle, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            controller.dismiss(animated: true, completion: nil)
        }))
        present(controller, animated: true, completion: nil)
    }
    
    func debugAnnotationViewFor(_ annotation: DebugAnnotation) -> DebugAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "debugView") as? DebugAnnotationView
        if annotationView == nil {
            annotationView = DebugAnnotationView(reuseIdentifier: "debugView")
            annotationView?.frame = CGRect(origin: .zero, size: CGSize(width: 20, height: 20))
            annotationView?.layer.cornerRadius = annotationView!.bounds.midX
            annotationView?.layer.borderColor = UIColor.white.cgColor
            annotationView?.layer.borderWidth = 1
            annotationView?.layer.shadowColor = UIColor.black.cgColor
            annotationView?.layer.shadowOpacity = 0.1
        }
        
        annotationView?.backgroundColor = annotation.color.withAlphaComponent(0.5)
        
        return annotationView
    }
}
