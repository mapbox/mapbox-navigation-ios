//
//  SearchResultRecord.swift
//  Dash
//
//  Created by Maksim Chizhavko on 1/10/25.
//

import CoreLocation
import Foundation
import MapKit

@_spi(MapboxInternal)
public struct SearchResultRecord {
    public let id: String
    public var serverIndex: Int?
    public let coordinate: CLLocationCoordinate2D
    public let placemark: MKPlacemark
    public let name: String
    public let descriptionText: String?
    public let estimatedTime: TimeInterval?
    public let estimatedDistance: CLLocationDistance?

    public var indexStringValue: String {
        .init((serverIndex ?? 0) + 1)
    }

    public init(
        id: String,
        serverIndex: Int? = nil,
        coordinate: CLLocationCoordinate2D,
        placemark: MKPlacemark,
        name: String,
        descriptionText: String?,
        estimatedTime: TimeInterval?,
        estimatedDistance: CLLocationDistance?
    ) {
        self.id = id
        self.serverIndex = serverIndex
        self.coordinate = coordinate
        self.placemark = placemark
        self.name = name
        self.descriptionText = descriptionText
        self.estimatedTime = estimatedTime
        self.estimatedDistance = estimatedDistance
    }
}
