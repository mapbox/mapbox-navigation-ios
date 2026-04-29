//
//  CarPlaySearchControllerCategory.swift
//
//
//  Created by Maksim Chizhavko on 12/16/24.
//

import CoreLocation
import UIKit

@_spi(MapboxInternal)
public struct CarPlaySearchControllerCategory: Equatable, Hashable, Sendable {
    public let displayName: String
    public let icon: UIImage

    public init(displayName: String, icon: UIImage) {
        self.displayName = displayName
        self.icon = icon
    }
}
