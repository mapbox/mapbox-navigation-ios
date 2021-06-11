import CarPlay
import MapboxDirections

@available(iOS 12.0, *)
public protocol CarPlaySearchControllerDelegate: AnyObject {
    
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void)
    
    func resetPanButtons(_ mapTemplate: CPMapTemplate)
    
    func pushTemplate(_ template: CPTemplate, animated: Bool)
    
    func popTemplate(animated: Bool)
}
