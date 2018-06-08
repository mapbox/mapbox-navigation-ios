//
//  ISO8061Formatter.swift
//  MapboxCoreNavigation
//
//  Created by Bobby Sudekum on 6/8/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

class ISO8601: DateFormatter {
    
    let formatter = DateFormatter()
    
    override init() {
        super.init()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
