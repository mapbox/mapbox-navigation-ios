import XCTest
import TestHelper
import MapboxNavigation
import MapboxMaps

class BuildingHighlightingTests: TestCase {

    func testHighlightBuildings() {
        ResourceOptionsManager.default.resourceOptions.accessToken = "pk.eyJ1IjoiZGFucGF0IiwiYSI6ImI0WThCVWMifQ.BP_j7Kiv5SNL-p-kTfXNxg"
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        
        let styleLoadedExpectation = expectation(description: "")
        
        navigationMapView.mapView.mapboxMap.onEvery(.styleLoaded, handler: { event in
            print("!!! \(navigationMapView.mapView.mapboxMap.style.JSON)")
            styleLoadedExpectation.fulfill()
        })
        
        wait(for: [styleLoadedExpectation], timeout: 10.0)
        
        let mapIdleExpectation = expectation(description: "")

        navigationMapView.mapView.mapboxMap.onEvery(.mapIdle, handler: { event in
            let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 37.755144833897376, longitude: -122.4151578961939),
                                              zoom: 18.0,
                                              bearing: 0.0,
                                              pitch: 0.0)
            navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
            
            mapIdleExpectation.fulfill()
        })
        
        wait(for: [mapIdleExpectation], timeout: 10.0)
        
        let featureQueryExpectation = XCTestExpectation(description: "Wait for building to be highlighted.")
        
        let buildingHighlightCoordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.79066471218174, longitude: -122.39581404166825),
            CLLocationCoordinate2D(latitude: 37.78999490647732, longitude: -122.39485917526815)
        ]
        navigationMapView.highlightBuildings(at: buildingHighlightCoordinates,
                                             in3D: true,
                                             completion: { (result) -> Void in
                                                if result == true {
                                                    featureQueryExpectation.fulfill()
                                                } else {
                                                    XCTFail("Building highlighted failed.")
                                                }
                                             })

        wait(for: [featureQueryExpectation], timeout: 5.0)
    }
}
