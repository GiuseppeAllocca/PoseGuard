//
//  PoseGuard__3_0_App.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI

@main
struct TrackingAppApp: App {
    @State private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionStore)
                .preferredColorScheme(.dark)
        }
    }
}
