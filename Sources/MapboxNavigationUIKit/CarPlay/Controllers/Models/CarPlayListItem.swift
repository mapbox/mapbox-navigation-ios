//
//  CarPlayListItem.swift
//
//
//  Created by Maksim Chizhavko on 12/16/24.
//

import CarPlay
import Foundation

@_spi(MapboxInternal)
public struct CarPlayListItem: Equatable, Hashable, Sendable {
    public let text: String
    public let detailText: String
    public let icon: UIImage
    public let location: CLLocation

    public init(text: String, detailText: String, icon: UIImage, location: CLLocation) {
        self.text = text
        self.detailText = detailText
        self.icon = icon
        self.location = location
    }
}
