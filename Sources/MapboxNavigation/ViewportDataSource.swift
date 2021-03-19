import MapboxMaps

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
