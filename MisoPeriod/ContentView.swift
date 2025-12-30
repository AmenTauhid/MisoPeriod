import SwiftUI

// ContentView is no longer the main entry point.
// MainTabView is now used as the root view.
// This file is kept for backward compatibility.

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
