import SwiftUI

struct MainTabView: View {
    @StateObject private var cycleViewModel = CycleViewModel()
    @State private var selectedTab = 0

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

            MisoInsightsView(viewModel: cycleViewModel)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            SettingsView(viewModel: cycleViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.misoPrimary)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: CycleViewModel
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingNotificationSettings = false
    @State private var cycleLengthInput: Int = 28
    @State private var periodLengthInput: Int = 5
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingPartnerShare = false

    private let exportService = DataExportService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                List {
                    // Notifications Section
                    Section {
                        Button {
                            showingNotificationSettings = true
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.misoPrimary)
                                    .frame(width: 28)

                                Text("Notifications")
                                    .foregroundColor(.misoTextPrimary)

                                Spacer()

                                if notificationService.isAuthorized {
                                    Text("On")
                                        .foregroundColor(.misoTextSecondary)
                                } else {
                                    Text("Off")
                                        .foregroundColor(.misoTextTertiary)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.misoTextTertiary)
                            }
                        }
                    } header: {
                        Text("Reminders")
                    }

                    // Cycle Settings Section
                    Section {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundColor(.misoSecondary)
                                .frame(width: 28)

                            Text("Average Cycle")

                            Spacer()

                            Picker("", selection: $cycleLengthInput) {
                                ForEach(21...40, id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.misoPrimary)
                            .onChange(of: cycleLengthInput) { _, newValue in
                                Task {
                                    await viewModel.updateSettings(cycleLength: newValue)
                                }
                            }
                        }

                        HStack {
                            Image(systemName: "drop.circle.fill")
                                .foregroundColor(.misoPeriod)
                                .frame(width: 28)

                            Text("Average Period")

                            Spacer()

                            Picker("", selection: $periodLengthInput) {
                                ForEach(2...10, id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.misoPrimary)
                            .onChange(of: periodLengthInput) { _, newValue in
                                Task {
                                    await viewModel.updateSettings(periodLength: newValue)
                                }
                            }
                        }
                    } header: {
                        Text("Cycle Settings")
                    } footer: {
                        Text("These values are used for predictions until enough data is logged.")
                    }

                    // Stats Section
                    Section {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            Text("Logging Streak")
                            Spacer()
                            Text("\(viewModel.loggingStreak) days")
                                .foregroundColor(.misoTextSecondary)
                        }
                    } header: {
                        Text("Stats")
                    }

                    // Sharing Section
                    Section {
                        Button {
                            showingPartnerShare = true
                        } label: {
                            HStack {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundColor(.pink)
                                    .frame(width: 28)

                                Text("Share with Partner")
                                    .foregroundColor(.misoTextPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.misoTextTertiary)
                            }
                        }
                    } header: {
                        Text("Partner Mode")
                    } footer: {
                        Text("Share your cycle summary via QR code or text.")
                    }

                    // Data Section
                    Section {
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.misoAccent)
                                    .frame(width: 28)

                                Text("Export Data")
                                    .foregroundColor(.misoTextPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.misoTextTertiary)
                            }
                        }
                    } header: {
                        Text("Your Data")
                    } footer: {
                        Text("Export all your cycle data as a JSON file.")
                    }

                    // Privacy Section
                    Section {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.misoAccent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy First")
                                    .foregroundColor(.misoTextPrimary)
                                Text("All data stored locally on your device")
                                    .font(.misoCaption)
                                    .foregroundColor(.misoTextSecondary)
                            }
                        }

                        HStack {
                            Image(systemName: "icloud.slash.fill")
                                .foregroundColor(.misoTextTertiary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No Cloud Sync")
                                    .foregroundColor(.misoTextPrimary)
                                Text("Your data never leaves your device")
                                    .font(.misoCaption)
                                    .foregroundColor(.misoTextSecondary)
                            }
                        }
                    } header: {
                        Text("Privacy")
                    }

                    // About Section
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.misoTextSecondary)
                        }

                        HStack {
                            Text("Made with")
                            Image(systemName: "heart.fill")
                                .foregroundColor(.misoPrimary)
                                .font(.caption)
                            Text("for you")
                        }
                        .foregroundColor(.misoTextSecondary)
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView(cycleViewModel: viewModel)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingPartnerShare) {
                PartnerShareView(viewModel: viewModel)
            }
            .onAppear {
                cycleLengthInput = viewModel.averageCycleLength
                periodLengthInput = Int(viewModel.userSettings?.averagePeriodLength ?? 5)
            }
        }
    }

    private func exportData() {
        do {
            exportURL = try exportService.exportToFile()
            showingShareSheet = true
        } catch {
            print("Export error: \(error)")
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MainTabView()
}
