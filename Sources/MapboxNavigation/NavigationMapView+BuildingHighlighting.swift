import MapboxMaps

// TODO: Implement the ability to highlight/unhighlight buildings in 2D/3D.
extension NavigationMapView {
    
    // MARK: - Building Extrusion Highlighting methods
    
    /**
     Receives coordinates for searching the map for buildings. If buildings are found, they will be highlighted in 2D or 3D depending on the `in3D` value.
     
     - parameter coordinates: Coordinates which represent building locations.
     - parameter extrudesBuildings: Switch which allows to highlight buildings in either 2D or 3D. Defaults to true.
     
     - returns: Bool indicating if number of buildings found equals number of coordinates supplied.
     */
    @discardableResult public func highlightBuildings(at coordinates: [CLLocationCoordinate2D], in3D extrudesBuildings: Bool = true) -> Bool {
        return false
    }
    
    /**
     Removes the highlight from all buildings highlighted by `highlightBuildings(at:in3D:)`.
     */
    public func unhighlightBuildings() {
        
    }
}
