//
//  MisoPeriodApp.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-12-29.
//

import SwiftUI
import CoreData

@main
struct MisoPeriodApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
