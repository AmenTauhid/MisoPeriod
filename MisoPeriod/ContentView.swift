import SwiftUI

struct ContentView: View {
    @StateObject private var cycleViewModel = CycleViewModel()
    @State private var showingOnboarding = false

    var body: some View {
        MainTabViewWithViewModel(viewModel: cycleViewModel)
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(viewModel: cycleViewModel, isPresented: $showingOnboarding)
            }
            .onAppear {
                checkOnboarding()
            }
            .onChange(of: cycleViewModel.hasCompletedOnboarding) { _, completed in
                if !completed {
                    showingOnboarding = true
                }
            }
    }

    private func checkOnboarding() {
        // Small delay to let view model load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !cycleViewModel.hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
    }
}

// Wrapper to pass existing view model
struct MainTabViewWithViewModel: View {
    @ObservedObject var viewModel: CycleViewModel

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MisoCalendarView(cycleViewModel: viewModel)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            MisoInsightsView(viewModel: viewModel)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.misoPrimary)
    }
}

#Preview {
    ContentView()
}
 
