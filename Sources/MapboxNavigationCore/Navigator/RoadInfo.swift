//
//  RoadInfo.swift
//
//
//  Created by Maksim Chizhavko on 1/17/24.
//

import Foundation
import MapboxDirections

public struct RoadInfo: Equatable, Sendable {
    /// the country code (ISO-2 format) of the road
    public let countryCodeIso2: String?

    /// right-hand or left-hand traffic type
    public let drivingSide: DrivingSide

    /// true if current road is one-way.
    public let isOneWay: Bool

    /// the number of lanes
    public let laneCount: Int?

    /// The edge’s general road classes.
    public let roadClasses: RoadClasses

    public init(
        countryCodeIso2: String?,
        drivingSide: DrivingSide,
        isOneWay: Bool,
        laneCount: Int?,
        roadClasses: RoadClasses
    ) {
        self.countryCodeIso2 = countryCodeIso2
        self.drivingSide = drivingSide
        self.isOneWay = isOneWay
        self.laneCount = laneCount
        self.roadClasses = roadClasses
    }
}
