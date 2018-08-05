import Foundation
import CarPlay
import MapboxDirections

@available(iOS 12.0, *)
extension CPMapTemplate {
    public func showTripPreviews(_ routes: [Route], textConfiguration: CPTripPreviewTextConfiguration?) {
        guard let origin = routes.first?.legs.first?.source else { return }
        guard let destination = routes.last?.legs.last?.destination else { return }
        
        let routeChoices: [CPRouteChoice] = routes.map {
            let summary = $0.description.components(separatedBy: ", ")
            return CPRouteChoice(summaryVariants: [summary.first ?? ""],
                                 additionalInformationVariants: [summary.last ?? ""],
                                 selectionSummaryVariants: [])
        }
        
        let trip = CPTrip(origin: MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate)),
                      destination: MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate, addressDictionary: [
                        "street": destination.name ?? ""
                        ])),
                      routeChoices: routeChoices)
        
        let defaultPreviewText = CPTripPreviewTextConfiguration(startButtonTitle: "Go", additionalRoutesButtonTitle: "Addition Routes", overviewButtonTitle: "Overview")
        
        // This function crashes without the optional `textConfiguration` provided.
        showTripPreviews([trip], textConfiguration: textConfiguration ?? defaultPreviewText)
    }
}
