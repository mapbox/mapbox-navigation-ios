//
//  CircularView.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 9/26/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import UIKit

class CircularView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.size.width / 2
    }
}
