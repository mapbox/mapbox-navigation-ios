//
//  NibLoaded.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 10/12/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import UIKit

protocol NibLoadable{
//    var nibName: String? { get }
}

extension NibLoadable where Self: UIView {
//    var nibName: String? { return nil }
    
    func loadNib(from bundle: Bundle? = nil, named name: String? = nil) -> UIView? {
        let nibBundle = bundle ?? localBundle
        let nibName = name ?? String(describing: self)
        
        guard let nib = nibBundle.loadNibNamed(nibName, owner: self, options: nil) else { return nil }
        
        let content = nib.first! as! UIView
        
        return content
    }
}
