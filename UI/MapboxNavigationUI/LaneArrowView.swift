//
//  LaneArrowView.swift
//
//  Created by Bobby Sudekum on 11/8/16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

class LaneArrowView: UIView {
    @IBInspectable
    var scale: CGFloat = 1
    let invalidAlpha: CGFloat = 0.4
    
    var lane: Lane?
    var maneuverDirection: ManeuverDirection?
    var isValid: Bool = false
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let lane = lane {
            var flipLane: Bool
            if lane.indications.isSuperset(of: [.straightAhead, .sharpRight]) || lane.indications.isSuperset(of: [.straightAhead, .right]) || lane.indications.isSuperset(of: [.straightAhead, .slightRight]) {
                if !isValid {
                    StyleKitArrows.drawLane_straight_right()
                    alpha = invalidAlpha
                } else if maneuverDirection == .straightAhead {
                    StyleKitArrows.drawLane_straight_only()
                } else {
                    StyleKitArrows.drawLane_right_only()
                }
                flipLane = false
            } else if lane.indications.isSuperset(of: [.straightAhead, .sharpLeft]) || lane.indications.isSuperset(of: [.straightAhead, .left]) || lane.indications.isSuperset(of: [.straightAhead, .slightLeft]) {
                if !isValid {
                    StyleKitArrows.drawLane_straight_right()
                    alpha = invalidAlpha
                } else if maneuverDirection == .straightAhead {
                    StyleKitArrows.drawLane_straight_only()
                } else {
                    StyleKitArrows.drawLane_right_only()
                }
                flipLane = true
            } else if lane.indications.description.components(separatedBy: ",").count >= 2 {
                // Hack:
                // Account for a configuation where there is no straight lane
                // but there are at least 2 indications.
                // In this situation, just draw a left/right arrow
                if maneuverDirection == .sharpRight || maneuverDirection == .right || maneuverDirection == .slightRight {
                    StyleKitArrows.drawLane_right_h()
                    flipLane = false
                } else {
                    StyleKitArrows.drawLane_right_h()
                    flipLane = true
                }
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.sharpRight]) || lane.indications.isSuperset(of: [.right]) || lane.indications.isSuperset(of: [.slightRight]) {
                StyleKitArrows.drawLane_right_h()
                flipLane = false
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.sharpLeft]) || lane.indications.isSuperset(of: [.left]) || lane.indications.isSuperset(of: [.slightLeft]) {
                StyleKitArrows.drawLane_right_h()
                flipLane = true
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.straightAhead]) {
                StyleKitArrows.drawLane_straight()
                flipLane = false
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.uTurn]) {
                StyleKitArrows.drawLane_uturn()
                flipLane = false
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isEmpty && isValid {
                // If the lane indication is `none` and the maneuver modifier has a turn in it,
                // show the turn in the lane image.
                if maneuverDirection == .sharpRight || maneuverDirection == .right || maneuverDirection == .slightRight {
                    StyleKitArrows.drawLane_right_only()
                    flipLane = false
                } else if maneuverDirection == .sharpLeft || maneuverDirection == .left || maneuverDirection == .slightLeft {
                    StyleKitArrows.drawLane_right_only()
                    flipLane = true
                } else {
                    StyleKitArrows.drawLane_straight()
                    flipLane = false
                }
            } else {
                StyleKitArrows.drawLane_straight()
                flipLane = false
                alpha = isValid ? 1 : invalidAlpha
            }
            
            transform = CGAffineTransform(scaleX: flipLane ? -1 : 1, y: 1)
        }
    }
}
