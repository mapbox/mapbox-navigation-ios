protocol DestinationPreviewViewControllerDelegate: AnyObject {
    
    func willPreviewRoutes(_ destinationPreviewViewController: DestinationPreviewViewController)
    
    func willStartNavigation(_ destinationPreviewViewController: DestinationPreviewViewController)
}
