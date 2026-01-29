import CoreLocation
import Foundation
@_spi(Experimental) import MapboxMaps
import MapboxNavigationCore

extension NavigationMapView {
    /// Queries building features at a specific coordinate on the map.
    ///
    /// - Parameter coordinate: The geographic coordinate to query buildings at.
    /// - Returns: An array of building features found at the specified location.
    /// - Throws: An error if the query fails.
    ///
    /// ## Example Usage
    /// ```swift
    /// Task {
    ///     do {
    ///         let buildings = try await navigationMapView.queryBuildings(at: coordinate)
    ///         print("Found \(buildings.count) buildings")
    ///     } catch {
    ///         print("Failed to query buildings: \(error)")
    ///     }
    /// }
    /// ```
    @MainActor
    public func queryBuildings(at coordinate: CLLocationCoordinate2D) async throws -> [StandardBuildingsFeature] {
        let screenPoint = mapView.mapboxMap.point(for: coordinate)
        let rectSize = poiClickableAreaSize
        let rect = CGRect(
            x: screenPoint.x - rectSize / 2,
            y: screenPoint.y - rectSize / 2,
            width: rectSize,
            height: rectSize
        )

        return try await withCheckedThrowingContinuation { continuation in
            _ = mapView.mapboxMap.queryRenderedFeatures(with: rect, featureset: .standardBuildings) { result in
                continuation.resume(with: result)
            }
        }
    }
}
