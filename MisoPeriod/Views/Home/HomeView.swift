import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: CycleViewModel
    @State private var showingStartPeriod = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Greeting & Affirmation
                        greetingSection

                        // Cycle Status Card
                        cycleStatusCard

                        // Quick Actions
                        quickActionsSection

                        // Prediction Card
                        if !viewModel.isOnPeriod {
                            predictionCard
                        }

                        // Fertile Window Card
                        if viewModel.isInFertileWindow {
                            fertileWindowCard
                        }

                        // Today's Log Status
                        todayLogCard

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("MisoPeriod")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
        }
        .alert("Start New Period", isPresented: $showingStartPeriod) {
            Button("Start Today") {
                Task {
                    await viewModel.startPeriod()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark today as the first day of your period?")
        }
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text(viewModel.currentAffirmation)
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
                .italic()
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentPhase.backgroundColor)
        )
        .onTapGesture {
            viewModel.showNewAffirmation()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        case 17..<21: return "Good evening!"
        default: return "Hello!"
        }
    }

    // MARK: - Cycle Status Card
    private var cycleStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cycle Day")
                        .font(.misoCaption)
                        .foregroundColor(.misoTextSecondary)

                    Text("\(viewModel.cycleDay)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.misoPrimary)
                }

                Spacer()

                // Phase indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: viewModel.currentPhase.icon)
                        .font(.title)
                        .foregroundColor(viewModel.currentPhase.color)

                    Text(viewModel.currentPhase.displayName)
                        .font(.misoHeadline)
                        .foregroundColor(.misoTextPrimary)

                    Text(viewModel.currentPhase.shortDescription)
                        .font(.misoCaption)
                        .foregroundColor(.misoTextSecondary)
                }
            }

            // Progress bar
            cycleProgressBar

            // Period status
            if viewModel.isOnPeriod {
                periodActiveView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.misoBgCard)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var cycleProgressBar: some View {
        GeometryReader { geometry in
            let progress = min(CGFloat(viewModel.cycleDay) / CGFloat(viewModel.averageCycleLength), 1.0)

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.misoBgSecondary)
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [viewModel.currentPhase.color, viewModel.currentPhase.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }

    private var periodActiveView: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.misoPeriod)

            Text("Period in progress")
                .font(.misoSubheadline)
                .foregroundColor(.misoTextPrimary)

            Spacer()

            Button("End Period") {
                Task {
                    await viewModel.endPeriod()
                }
            }
            .font(.misoSubheadline.bold())
            .foregroundColor(.misoPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.misoPeriod.opacity(0.1))
        )
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            if !viewModel.isOnPeriod {
                QuickActionButton(
                    title: "Period Started",
                    icon: "drop.fill",
                    color: .misoPrimary
                ) {
                    showingStartPeriod = true
                }
            }

            QuickActionButton(
                title: viewModel.hasLoggedToday ? "Edit Today" : "Log Today",
                icon: viewModel.hasLoggedToday ? "checkmark.circle.fill" : "pencil.circle.fill",
                color: viewModel.hasLoggedToday ? .misoSecondary : .misoAccent
            ) {
                // Will trigger sheet from MainTabView
            }
        }
    }

    // MARK: - Prediction Card
    private var predictionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.misoPrimary)
                Text("Next Period")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
                Spacer()
            }

            if let days = viewModel.daysUntilPeriod, days > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("in")
                        .font(.misoBody)
                        .foregroundColor(.misoTextSecondary)

                    Text("\(days)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.misoPrimary)

                    Text(days == 1 ? "day" : "days")
                        .font(.misoBody)
                        .foregroundColor(.misoTextSecondary)
                }

                if let nextDate = viewModel.nextPeriodDate {
                    Text(nextDate.mediumDateString)
                        .font(.misoCaption)
                        .foregroundColor(.misoTextTertiary)
                }
            } else {
                Text("Log more cycles for predictions")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Fertile Window Card
    private var fertileWindowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.misoFertile)
                Text("Fertile Window")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
                Spacer()

                Text("Active")
                    .font(.misoCaption.bold())
                    .foregroundColor(.misoFertile)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.misoFertile.opacity(0.2))
                    )
            }

            if let dates = viewModel.fertileWindowDates {
                Text("\(dates.start.shortDateString) - \(dates.end.shortDateString)")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoFertile.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.misoFertile.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Today's Log Card
    private var todayLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.hasLoggedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.hasLoggedToday ? .misoSecondary : .misoTextTertiary)
                Text("Today's Log")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
                Spacer()

                if viewModel.loggingStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.loggingStreak)")
                            .font(.misoCaption.bold())
                            .foregroundColor(.orange)
                    }
                }
            }

            if viewModel.hasLoggedToday, let log = viewModel.todayLog {
                HStack(spacing: 16) {
                    if log.flow.isPeriod {
                        Label(log.flow.displayName, systemImage: "drop.fill")
                            .font(.misoCaption)
                            .foregroundColor(.misoPeriod)
                    }

                    if log.mood > 0 {
                        Label("Mood: \(log.mood)/5", systemImage: "face.smiling")
                            .font(.misoCaption)
                            .foregroundColor(.misoAccent)
                    }

                    if !log.symptomTypes.isEmpty {
                        Label("\(log.symptomTypes.count) symptoms", systemImage: "list.bullet")
                            .font(.misoCaption)
                            .foregroundColor(.misoTextSecondary)
                    }
                }
            } else {
                Text("Tap to log how you're feeling today")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.misoCaption)
                    .foregroundColor(.misoTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView(viewModel: CycleViewModel.preview)
}
