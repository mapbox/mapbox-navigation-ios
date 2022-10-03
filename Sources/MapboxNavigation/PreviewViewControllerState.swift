extension Preview {
    
    // :nodoc:
    public enum State {
        
        case browsing
        
        case destinationPreviewing(_ destinationOptions: DestinationOptions)
        
        case routesPreviewing(_ routesPreviewOptions: RoutesPreviewOptions)
    }
}
