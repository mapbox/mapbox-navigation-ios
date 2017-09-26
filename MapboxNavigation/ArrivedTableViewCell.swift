//
//  ArrivedTableViewCell.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 9/26/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation


class ArrivedTableViewCell: UITableViewCell, MGLMapViewDelegate {

    @IBOutlet weak var feedbacksAdded: UILabel!
    @IBOutlet weak var mapView: NavigationMapView!
    
    static let mapInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    
    override func awakeFromNib() {
        mapView.delegate = self
    }
    var route: Route?
    
    var feedbacks: [FeedbackEvent]? {
        didSet {
            guard let feedbacks = feedbacks else { return }
            updateFeedbacks(with: feedbacks)
        }
    }
    
    private func updateMap(with route: Route) {
        mapView.showRoute(route)
        
        if let coordinates = route.coordinates {
            mapView.showRoute(route)
            let polyline = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
            mapView.setVisibleCoordinateBounds(polyline.overlayBounds, edgePadding: ArrivedTableViewCell.mapInsets, animated: false)
        }
    }
    private func updateFeedbacks(with feedbacks: [CoreFeedbackEvent]) {
        feedbacksAdded.text = "\(feedbacks.count) feedbacks added"
    }
    
    //MARK: - MGLMapViewDelegate Methods
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        guard let route = route else { return }
        updateMap(with: route)
        
        if let annotations: [MGLAnnotation] = feedbacks?.flatMap(MGLPointAnnotation.init(feedback:)) {
            mapView.addAnnotations(annotations)
        }
    }
}

fileprivate extension MGLPointAnnotation {
    convenience init?(feedback: FeedbackEvent) {
        guard let coord = feedback.coordinate else { return nil }
        self.init()
        self.coordinate = coord
    }
}
