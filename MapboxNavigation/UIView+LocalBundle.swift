//
//  UIView+LocalBundle
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 10/12/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation


extension UIView {
    var localBundle: Bundle {
        return Bundle(for: type(of: self))
    }
}
