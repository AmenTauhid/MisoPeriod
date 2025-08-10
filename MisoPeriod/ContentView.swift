//
//  ContentView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        PeriodTrackerView()
            .environment(\.managedObjectContext, viewContext)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
