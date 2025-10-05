//
//  WishKeep_V2App.swift
//  WishKeep V2
//
//  Created by Addison Pratt on 10/4/25.
//

import SwiftUI
import CoreData

@main
struct WishKeep_V2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
