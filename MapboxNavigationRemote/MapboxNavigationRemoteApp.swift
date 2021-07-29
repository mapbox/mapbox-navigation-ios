//
//  MapboxNavigationRemoteApp.swift
//  MapboxNavigationRemote
//
//  Created by Aliaksandr Bialiauski on 29.07.21.
//  Copyright © 2021 Mapbox. All rights reserved.
//

import SwiftUI

@main
struct MapboxNavigationRemoteApp: App {
    init() {
        Current.setupRemoteCli()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(Current.dataSource)
            }
        }
    }
}
