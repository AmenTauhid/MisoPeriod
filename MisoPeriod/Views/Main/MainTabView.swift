import SwiftUI

struct MainTabView: View {
    @StateObject private var cycleViewModel = CycleViewModel()
    @State private var selectedTab = 0
    @State private var showingLogSheet = false

    var body: some View {
        ZStack {
            Color.misoBgPrimary.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView(viewModel: cycleViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                MisoCalendarView(cycleViewModel: cycleViewModel)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(1)

                // Center log button placeholder
                Color.clear
                    .tabItem {
                        Label("Log", systemImage: "plus.circle.fill")
                    }
                    .tag(2)

                InsightsView(viewModel: cycleViewModel)
                    .tabItem {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(3)

                SettingsView(viewModel: cycleViewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(.misoPrimary)
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 2 {
                    showingLogSheet = true
                    // Reset to previous tab
                    selectedTab = 0
                }
            }

            // Floating action button for logging
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.misoPrimary, .misoPrimary.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: .misoPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .offset(y: -30)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            DailyLogView(viewModel: cycleViewModel, isPresented: $showingLogSheet)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct InsightsView: View {
    @ObservedObject var viewModel: CycleViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.misoAccent.opacity(0.5))

                    Text("Insights Coming Soon")
                        .font(.misoTitle2)
                        .foregroundColor(.misoTextSecondary)

                    Text("Understand your patterns")
                        .font(.misoBody)
                        .foregroundColor(.misoTextTertiary)
                }
            }
            .navigationTitle("Insights")
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: CycleViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                List {
                    Section("Cycle Settings") {
                        HStack {
                            Text("Average Cycle Length")
                            Spacer()
                            Text("\(viewModel.averageCycleLength) days")
                                .foregroundColor(.misoTextSecondary)
                        }
                    }

                    Section("Privacy") {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.misoAccent)
                            Text("All data stored locally")
                        }
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.misoTextSecondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
}
