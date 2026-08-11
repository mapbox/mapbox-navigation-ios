//
//  CarPlayListItem.swift
//
//
//  Created by Maksim Chizhavko on 12/16/24.
//

import CarPlay
import Foundation
import MapboxNavigationCore

@_spi(MapboxInternal)
public struct CarPlayListItem: Equatable, Hashable, Sendable {
    public let text: String
    public let detailText: String?
    public let icon: UIImage?
    public let location: CLLocation?
    /// Optional source record associated with this item. When the user selects this item and Dash hands it to
    /// ``CarPlayManager.previewRoutes(to:searchResultRecord:)``, the record is attached to each route choice and
    /// retrievable later via ``CPRouteChoice/searchResult``.
    public let searchResultRecord: SearchResultRecord?

    public init(
        text: String,
        detailText: String?,
        icon: UIImage?,
        location: CLLocation?,
        searchResultRecord: SearchResultRecord? = nil
    ) {
        self.text = text
        self.detailText = detailText
        self.icon = icon
        self.location = location
        self.searchResultRecord = searchResultRecord
    }
}
