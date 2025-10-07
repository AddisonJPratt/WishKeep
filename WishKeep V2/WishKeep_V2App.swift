//
//  WishKeep_V2App.swift
//  WishKeep V2
//
//  Created by Addison Pratt on 10/4/25.
//

import SwiftUI
import SwiftData

@main
struct WishKeep_V2App: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(persistenceController.container)
        }
    }
}

