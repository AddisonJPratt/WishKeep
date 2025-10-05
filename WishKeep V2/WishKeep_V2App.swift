//
//  WishKeep_V2App.swift
//  WishKeep V2
//
//  Created by Addison Pratt on 10/4/25.
//

import SwiftUI
internal import CoreData

@main
struct WishKeep_V2App: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

