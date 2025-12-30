import SwiftUI

struct MainTabView: View {
    @StateObject private var cycleViewModel = CycleViewModel()
    @State private var selectedTab = 0
    @State private var showingLogOptions = false
    @State private var showingDailyLog = false
    @State private var showingPeriodEntry = false
    @State private var showingDeleteLog = false
    @State private var previousTab = 0

    var body: some View {
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

            // Log tab - triggers sheet
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
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                showingLogOptions = true
                // Return to previous tab
                selectedTab = oldValue
            } else {
                previousTab = newValue
            }
        }
        .confirmationDialog("What would you like to do?", isPresented: $showingLogOptions, titleVisibility: .visible) {
            Button("Log Today") {
                showingDailyLog = true
            }
            Button("Log Period (Date Range)") {
                showingPeriodEntry = true
            }
            Button("Delete Log", role: .destructive) {
                showingDeleteLog = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingDailyLog) {
            DailyLogView(viewModel: cycleViewModel, isPresented: $showingDailyLog)
        }
        .sheet(isPresented: $showingPeriodEntry) {
            PeriodEntryView(viewModel: cycleViewModel, isPresented: $showingPeriodEntry)
        }
        .sheet(isPresented: $showingDeleteLog) {
            DeleteLogView(viewModel: cycleViewModel, isPresented: $showingDeleteLog)
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
