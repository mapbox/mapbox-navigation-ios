//
//  Dictionary.swift
//  MapboxCoreNavigation
//
//  Created by Bobby Sudekum on 6/14/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

extension Dictionary {
    func asString() -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(data: data, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
