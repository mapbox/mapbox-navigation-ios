import MapboxMaps

// TODO: Consider adding `CameraOptions` properties for navigation in free-drive and active guidance navigations.
// Possible `CameraOptions` (iOS, CarPlay):
// 1. Following, during free drive.
// 2. Following, during active guidance navigation.
// 3. Following, during active guidance navigation when driving on motorway.
// 4. Following, during active guidance navigation when building highlighting is enabled.
// 5. Following, after manual request by pressing Resume button.
// 6. Following, after re-routing.
// 7. Overview, after manual request by pressing Overview button.
// 8. Overview, after re-routing.
// 9. Idle, after arriving to final destination.
// 10. Idle, after selecting specific maneuver in top banner menu.
public protocol ViewportDataSource {
    
    var delegate: ViewportDataSourceDelegate? { get set }
    
    var followingMobileCamera: CameraOptions { get }
    
    var followingHeadUnitCamera: CameraOptions { get }
    
    var overviewMobileCamera: CameraOptions { get }
    
    var overviewHeadUnitCamera: CameraOptions { get }
}

public protocol ViewportDataSourceDelegate {
    
    func viewportDataSource(_ dataSource: ViewportDataSource, didUpdate cameraOptions: [String: CameraOptions])
}
