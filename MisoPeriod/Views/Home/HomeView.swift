import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: CycleViewModel
    @StateObject private var predictionService = PredictionService()
    @State private var showingStartPeriod = false
    @State private var showingAlertDetail = false
    @State private var showingStreakCelebration = false
    @State private var celebrationTitle = ""
    @State private var celebrationSubtitle = ""
    @State private var showHearts = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Greeting & Affirmation
                        greetingSection

                        // Streak milestone banner
                        if shouldShowStreakBanner {
                            streakMilestoneBanner
                        }

                        // Alert Banner (if any)
                        if let alert = predictionService.topAlert {
                            alertBanner(alert)
                        }

                        // Cycle Status Card
                        cycleStatusCard

                        // Quick Actions
                        quickActionsSection

                        // Period approaching heads up
                        if let days = viewModel.daysUntilPeriod, days > 0 && days <= 3 && !viewModel.isOnPeriod {
                            periodApproachingCard(daysUntil: days)
                        }

                        // Prediction Card
                        if !viewModel.isOnPeriod {
                            predictionCard
                        }

                        // Fertile Window Card
                        if viewModel.isInFertileWindow || predictionService.isInFertileWindow {
                            fertileWindowCard
                        }

                        // Symptom Prediction Card
                        if !predictionService.topPredictedSymptoms.isEmpty {
                            symptomPredictionCard
                        }

                        // Today's Log Status
                        todayLogCard

                        // Cycle Insights
                        if predictionService.cyclesAnalyzed >= 2 {
                            insightsCard
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }

                // Heart animation overlay
                HeartAnimation(isActive: $showHearts)
            }
            .navigationTitle("MisoPeriod")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
                await predictionService.updatePredictions()
            }
            .task {
                await predictionService.updatePredictions()
            }
        }
        .alert("Start New Period", isPresented: $showingStartPeriod) {
            Button("Start Today") {
                Task {
                    await viewModel.startPeriod()
                    await predictionService.updatePredictions()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark today as the first day of your period?")
        }
        .celebrationOverlay(
            isShowing: $showingStreakCelebration,
            title: celebrationTitle,
            subtitle: celebrationSubtitle,
            icon: streakIcon,
            color: .orange
        )
        .onChange(of: viewModel.loggingStreak) { oldValue, newValue in
            checkStreakMilestone(oldValue: oldValue, newValue: newValue)
        }
    }

    // MARK: - Streak Helpers
    private var shouldShowStreakBanner: Bool {
        viewModel.loggingStreak >= 7
    }

    private var streakIcon: String {
        switch viewModel.loggingStreak {
        case 7..<14: return "flame.fill"
        case 14..<30: return "star.fill"
        case 30..<60: return "trophy.fill"
        default: return "crown.fill"
        }
    }

    private func checkStreakMilestone(oldValue: Int, newValue: Int) {
        let milestones = [3, 7, 14, 30, 60, 100]

        for milestone in milestones {
            if oldValue < milestone && newValue >= milestone {
                celebrationTitle = "\(milestone) Day Streak!"
                celebrationSubtitle = streakMessage(for: milestone)
                showingStreakCelebration = true
                break
            }
        }
    }

    private func streakMessage(for days: Int) -> String {
        switch days {
        case 3: return "You're building a great habit!"
        case 7: return "A whole week of tracking. Amazing!"
        case 14: return "Two weeks strong. You're incredible!"
        case 30: return "One month! You're a tracking superstar!"
        case 60: return "Two months of dedication. Wow!"
        case 100: return "100 days! You're absolutely amazing!"
        default: return "Keep up the great work!"
        }
    }

    // MARK: - Streak Milestone Banner
    private var streakMilestoneBanner: some View {
        HStack(spacing: 12) {
            StreakBadge(streak: viewModel.loggingStreak)

            VStack(alignment: .leading, spacing: 2) {
                Text("You're on fire!")
                    .font(.misoSubheadline.bold())
                    .foregroundColor(.misoTextPrimary)

                Text("\(viewModel.loggingStreak) day logging streak")
                    .font(.misoCaption)
                    .foregroundColor(.misoTextSecondary)
            }

            Spacer()

            Button {
                showHearts = true
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(greeting)
                    .font(.misoTitle2)
                    .foregroundColor(.misoTextPrimary)

                Spacer()

                Text(viewModel.currentPhase.emoji)
                    .font(.title2)
            }

            Text(viewModel.currentAffirmation)
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
                .italic()
                .transition(.opacity)
                .id(viewModel.currentAffirmation) // For animation

            // Self-care tip
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(viewModel.currentPhase.color)

                Text(viewModel.currentPhase.selfCareTip)
                    .font(.misoCaption)
                    .foregroundColor(.misoTextTertiary)
            }
            .padding(.top, 4)

            // Tap hint
            Text("Tap for a new message")
                .font(.system(size: 10))
                .foregroundColor(.misoTextTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentPhase.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.currentPhase.color.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.showNewAffirmation()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Sweet dreams"
        }
    }

    // MARK: - Alert Banner
    private func alertBanner(_ alert: IrregularityDetector.IrregularityAlert) -> some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.icon)
                .foregroundColor(alert.severity.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.misoSubheadline.bold())
                    .foregroundColor(.misoTextPrimary)

                Text(alert.message)
                    .font(.misoCaption)
                    .foregroundColor(.misoTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.misoTextTertiary)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(alert.severity.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(alert.severity.color.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            showingAlertDetail = true
        }
        .sheet(isPresented: $showingAlertDetail) {
            AlertDetailSheet(alert: alert)
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
        VStack(spacing: 10) {
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
                        await predictionService.updatePredictions()
                    }
                }
                .font(.misoSubheadline.bold())
                .foregroundColor(.misoPrimary)
            }

            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundColor(.pink.opacity(0.6))

                Text(periodComfortMessage)
                    .font(.misoCaption)
                    .foregroundColor(.misoTextSecondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.misoPeriod.opacity(0.1))
        )
    }

    private var periodComfortMessage: String {
        let messages = [
            "Take care of yourself today",
            "You're doing amazing",
            "Rest when you need to",
            "Be extra gentle with yourself",
            "Hot drinks and cozy blankets",
            "You've got this"
        ]
        // Use cycle day as seed for consistent message each day
        let index = viewModel.cycleDay % messages.count
        return messages[index]
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

    // MARK: - Period Approaching Card
    private func periodApproachingCard(daysUntil: Int) -> some View {
        let message: String = {
            switch daysUntil {
            case 1: return "Tomorrow might be the day! Stock up on your essentials."
            case 2: return "Just a couple days away. Time to prepare your comfort kit!"
            case 3: return "Your period is coming soon. Maybe grab some supplies?"
            default: return "Your period is approaching."
            }
        }()

        let tip: String = {
            switch daysUntil {
            case 1: return "Hot water bottle, snacks, and cozy clothes ready?"
            case 2: return "Maybe schedule some lighter activities"
            case 3: return "Good time to stock up on chocolate"
            default: return "Take care of yourself"
            }
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.misoPrimary)
                Text("Heads Up!")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
                Spacer()

                Text(daysUntil == 1 ? "Tomorrow" : "in \(daysUntil) days")
                    .font(.misoCaption.bold())
                    .foregroundColor(.misoPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.misoPrimary.opacity(0.15))
                    )
            }

            Text(message)
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)

            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.pink.opacity(0.7))

                Text(tip)
                    .font(.misoCaption)
                    .foregroundColor(.misoTextTertiary)
                    .italic()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.misoPrimary.opacity(0.08), Color.pink.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.misoPrimary.opacity(0.2), lineWidth: 1)
                )
        )
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

                // Confidence indicator
                if predictionService.cyclesAnalyzed >= 2 {
                    Text(predictionService.confidenceText)
                        .font(.misoCaption)
                        .foregroundColor(.misoTextTertiary)
                }
            }

            if let prediction = predictionService.periodPrediction {
                let days = prediction.daysUntil

                if days > 0 {
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

                    // Date range
                    HStack(spacing: 4) {
                        Text(prediction.predictedStartDate.mediumDateString)
                            .font(.misoCaption)
                            .foregroundColor(.misoTextSecondary)

                        if prediction.confidence < 0.7 {
                            Text("(±\(prediction.confidenceInterval.early.daysBetween(prediction.predictedStartDate).magnitude) days)")
                                .font(.misoCaption)
                                .foregroundColor(.misoTextTertiary)
                        }
                    }
                } else if days == 0 {
                    Text("Period expected today")
                        .font(.misoHeadline)
                        .foregroundColor(.misoPrimary)
                } else {
                    Text("Period may have started")
                        .font(.misoHeadline)
                        .foregroundColor(.misoPrimary)
                }
            } else if let days = viewModel.daysUntilPeriod, days > 0 {
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

                if predictionService.isInFertileWindow {
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
            }

            if let window = predictionService.fertilityWindow {
                Text("\(window.startDate.shortDateString) - \(window.endDate.shortDateString)")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)

                Text("Ovulation: \(window.ovulationDate.shortDateString)")
                    .font(.misoCaption)
                    .foregroundColor(.misoOvulation)
            } else if let dates = viewModel.fertileWindowDates {
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

    // MARK: - Symptom Prediction Card
    private var symptomPredictionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.misoAccent)
                Text("What to Expect")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
                Spacer()

                // Discomfort indicator
                DiscomfortIndicator(level: predictionService.todayDiscomfortLevel)
            }

            if let message = predictionService.symptomPrepMessage {
                Text(message)
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
            }

            // Top predicted symptoms
            FlowLayout(spacing: 8) {
                ForEach(predictionService.topPredictedSymptoms.prefix(4), id: \.symptom) { prediction in
                    SymptomPredictionChip(prediction: prediction)
                }
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

    // MARK: - Insights Card
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.misoAccent)
                Text("Cycle Insights")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
            }

            if let stats = predictionService.cycleStatistics {
                HStack(spacing: 20) {
                    InsightMiniCard(
                        title: "Avg Cycle",
                        value: "\(Int(stats.averageCycleLength))d",
                        icon: "arrow.triangle.2.circlepath"
                    )

                    InsightMiniCard(
                        title: "Avg Period",
                        value: "\(Int(stats.averagePeriodLength))d",
                        icon: "drop.fill"
                    )

                    InsightMiniCard(
                        title: "Regularity",
                        value: "\(Int(stats.regularityScore * 100))%",
                        icon: stats.isRegular ? "checkmark.circle" : "exclamationmark.circle"
                    )
                }
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

// MARK: - Supporting Views

struct DiscomfortIndicator: View {
    let level: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < Int(level * 5) ? Color.misoPrimary : Color.misoBgSecondary)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

struct SymptomPredictionChip: View {
    let prediction: SymptomPredictor.SymptomPrediction

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: prediction.symptom.icon)
                .font(.caption2)

            Text(prediction.symptom.displayName)
                .font(.misoCaption)

            // Likelihood bar
            GeometryReader { geo in
                Capsule()
                    .fill(prediction.symptom.color.opacity(0.3))
                    .overlay(
                        Capsule()
                            .fill(prediction.symptom.color)
                            .frame(width: geo.size.width * prediction.likelihood),
                        alignment: .leading
                    )
            }
            .frame(width: 20, height: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(prediction.symptom.color.opacity(0.1))
        )
        .foregroundColor(prediction.symptom.color)
    }
}

struct InsightMiniCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.misoAccent)

            Text(value)
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            Text(title)
                .font(.misoCaption)
                .foregroundColor(.misoTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AlertDetailSheet: View {
    let alert: IrregularityDetector.IrregularityAlert
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Icon and title
                        VStack(spacing: 12) {
                            Image(systemName: alert.severity.icon)
                                .font(.system(size: 48))
                                .foregroundColor(alert.severity.color)

                            Text(alert.title)
                                .font(.misoTitle2)
                                .foregroundColor(.misoTextPrimary)
                        }
                        .padding()

                        // Message
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What we noticed")
                                .font(.misoHeadline)
                                .foregroundColor(.misoTextSecondary)

                            Text(alert.message)
                                .font(.misoBody)
                                .foregroundColor(.misoTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.misoBgCard)
                        )

                        // Recommendation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendation")
                                .font(.misoHeadline)
                                .foregroundColor(.misoTextSecondary)

                            Text(alert.recommendation)
                                .font(.misoBody)
                                .foregroundColor(.misoTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.misoSecondary.opacity(0.1))
                        )

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Health Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.misoPrimary)
                }
            }
        }
    }
}

// MARK: - Flow Layout for wrapping content
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
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
