import SwiftUI
import Charts

struct MisoInsightsView: View {
    @ObservedObject var viewModel: CycleViewModel
    @StateObject private var insightsViewModel = InsightsViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                if insightsViewModel.isLoading {
                    ProgressView()
                } else if insightsViewModel.hasEnoughData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Tab selector
                            insightsTabs

                            // Content based on selected tab
                            switch selectedTab {
                            case 0:
                                cycleInsights
                            case 1:
                                symptomInsights
                            case 2:
                                moodEnergyInsights
                            default:
                                cycleInsights
                            }

                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                } else {
                    notEnoughDataView
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await insightsViewModel.loadData()
            }
            .refreshable {
                await insightsViewModel.loadData()
            }
        }
    }

    // MARK: - Tabs
    private var insightsTabs: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: index))
                            .font(.title3)
                        Text(tabTitle(for: index))
                            .font(.misoCaption)
                    }
                    .foregroundColor(selectedTab == index ? .misoPrimary : .misoTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == index ?
                        Color.misoPrimary.opacity(0.1) : Color.clear
                    )
                }
            }
        }
        .background(Color.misoBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "calendar.circle"
        case 1: return "list.bullet.clipboard"
        case 2: return "heart.circle"
        default: return "chart.bar"
        }
    }

    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Cycles"
        case 1: return "Symptoms"
        case 2: return "Wellness"
        default: return ""
        }
    }

    // MARK: - Cycle Insights
    private var cycleInsights: some View {
        VStack(spacing: 20) {
            // Summary cards
            cycleSummaryCards

            // Cycle length chart
            cycleLengthChart

            // Period length chart
            periodLengthChart

            // Regularity indicator
            regularityCard
        }
    }

    private var cycleSummaryCards: some View {
        HStack(spacing: 12) {
            SummaryStatCard(
                title: "Avg Cycle",
                value: "\(insightsViewModel.averageCycleLength)",
                unit: "days",
                icon: "arrow.triangle.2.circlepath",
                color: .misoPrimary
            )

            SummaryStatCard(
                title: "Avg Period",
                value: "\(insightsViewModel.averagePeriodLength)",
                unit: "days",
                icon: "drop.fill",
                color: .misoPeriod
            )

            SummaryStatCard(
                title: "Cycles",
                value: "\(insightsViewModel.totalCycles)",
                unit: "tracked",
                icon: "chart.line.uptrend.xyaxis",
                color: .misoAccent
            )
        }
    }

    private var cycleLengthChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cycle Length Trend")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                Spacer()

                Text("Last \(insightsViewModel.cycleLengthData.count) cycles")
                    .font(.misoCaption)
                    .foregroundColor(.misoTextTertiary)
            }

            if !insightsViewModel.cycleLengthData.isEmpty {
                Chart(insightsViewModel.cycleLengthData) { item in
                    LineMark(
                        x: .value("Cycle", item.index),
                        y: .value("Days", item.length)
                    )
                    .foregroundStyle(Color.misoPrimary.gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Cycle", item.index),
                        y: .value("Days", item.length)
                    )
                    .foregroundStyle(Color.misoPrimary)

                    RuleMark(y: .value("Average", insightsViewModel.averageCycleLength))
                        .foregroundStyle(Color.misoTextTertiary.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 5]))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var periodLengthChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Period Length")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                Spacer()
            }

            if !insightsViewModel.periodLengthData.isEmpty {
                Chart(insightsViewModel.periodLengthData) { item in
                    BarMark(
                        x: .value("Cycle", item.index),
                        y: .value("Days", item.length)
                    )
                    .foregroundStyle(Color.misoPeriod.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var regularityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insightsViewModel.isRegular ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(insightsViewModel.isRegular ? .misoSecondary : .orange)

                Text(insightsViewModel.isRegular ? "Regular Cycles" : "Irregular Cycles")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                Spacer()

                Text("\(Int(insightsViewModel.regularityScore * 100))%")
                    .font(.misoTitle3)
                    .foregroundColor(insightsViewModel.isRegular ? .misoSecondary : .orange)
            }

            Text(insightsViewModel.regularityDescription)
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)

            // Regularity gauge
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.misoBgSecondary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow, .misoSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * insightsViewModel.regularityScore)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Symptom Insights
    private var symptomInsights: some View {
        VStack(spacing: 20) {
            // Most common symptoms
            topSymptomsCard

            // Symptom frequency chart
            symptomFrequencyChart

            // Symptoms by phase
            symptomsByPhaseCard
        }
    }

    private var topSymptomsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Common Symptoms")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            if insightsViewModel.topSymptoms.isEmpty {
                Text("Log more symptoms to see patterns")
                    .font(.misoBody)
                    .foregroundColor(.misoTextTertiary)
                    .padding()
            } else {
                ForEach(insightsViewModel.topSymptoms.prefix(5), id: \.symptom) { item in
                    HStack {
                        Image(systemName: item.symptom.icon)
                            .foregroundColor(item.symptom.color)
                            .frame(width: 24)

                        Text(item.symptom.displayName)
                            .font(.misoBody)
                            .foregroundColor(.misoTextPrimary)

                        Spacer()

                        Text("\(item.count)x")
                            .font(.misoSubheadline)
                            .foregroundColor(.misoTextSecondary)

                        // Frequency bar
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.symptom.color.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(item.symptom.color)
                                        .frame(width: geo.size.width * item.percentage),
                                    alignment: .leading
                                )
                        }
                        .frame(width: 60, height: 8)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var symptomFrequencyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Frequency")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            if !insightsViewModel.symptomChartData.isEmpty {
                Chart(insightsViewModel.symptomChartData.prefix(8), id: \.symptom) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Symptom", item.symptom.displayName)
                    )
                    .foregroundStyle(item.symptom.color.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .frame(height: CGFloat(min(insightsViewModel.symptomChartData.count, 8) * 40))
            } else {
                Text("No symptom data yet")
                    .font(.misoBody)
                    .foregroundColor(.misoTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var symptomsByPhaseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptoms by Cycle Phase")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            ForEach(CyclePhase.allCases, id: \.self) { phase in
                let symptoms = insightsViewModel.symptomsByPhase[phase] ?? []

                if !symptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: phase.icon)
                                .foregroundColor(phase.color)
                            Text(phase.displayName)
                                .font(.misoSubheadline)
                                .foregroundColor(.misoTextPrimary)
                        }

                        FlowLayout(spacing: 6) {
                            ForEach(symptoms.prefix(4), id: \.self) { symptom in
                                Text(symptom.displayName)
                                    .font(.misoCaption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(symptom.color.opacity(0.15))
                                    )
                                    .foregroundColor(symptom.color)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Mood & Energy Insights
    private var moodEnergyInsights: some View {
        VStack(spacing: 20) {
            // Average mood/energy
            moodEnergySummary

            // Mood trend chart
            moodTrendChart

            // Energy trend chart
            energyTrendChart

            // Mood by phase
            moodByPhaseCard
        }
    }

    private var moodEnergySummary: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(moodEmoji(for: insightsViewModel.averageMood))
                    .font(.system(size: 40))

                Text("Avg Mood")
                    .font(.misoCaption)
                    .foregroundColor(.misoTextSecondary)

                Text(String(format: "%.1f", insightsViewModel.averageMood))
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )

            VStack(spacing: 8) {
                Text(energyEmoji(for: insightsViewModel.averageEnergy))
                    .font(.system(size: 40))

                Text("Avg Energy")
                    .font(.misoCaption)
                    .foregroundColor(.misoTextSecondary)

                Text(String(format: "%.1f", insightsViewModel.averageEnergy))
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )
        }
    }

    private var moodTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trend (Last 30 Days)")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            if !insightsViewModel.moodData.isEmpty {
                Chart(insightsViewModel.moodData) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Mood", item.value)
                    )
                    .foregroundStyle(Color.misoAccent.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Mood", item.value)
                    )
                    .foregroundStyle(Color.misoAccent.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5])
                }
                .frame(height: 150)
            } else {
                Text("Log your mood to see trends")
                    .font(.misoBody)
                    .foregroundColor(.misoTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var energyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Energy Trend (Last 30 Days)")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            if !insightsViewModel.energyData.isEmpty {
                Chart(insightsViewModel.energyData) { item in
                    BarMark(
                        x: .value("Date", item.date),
                        y: .value("Energy", item.value)
                    )
                    .foregroundStyle(Color.misoSecondary.gradient)
                    .cornerRadius(2)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5])
                }
                .frame(height: 150)
            } else {
                Text("Log your energy to see trends")
                    .font(.misoBody)
                    .foregroundColor(.misoTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var moodByPhaseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Mood by Phase")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            ForEach(CyclePhase.allCases, id: \.self) { phase in
                let avgMood = insightsViewModel.moodByPhase[phase] ?? 0

                if avgMood > 0 {
                    HStack {
                        Image(systemName: phase.icon)
                            .foregroundColor(phase.color)
                            .frame(width: 24)

                        Text(phase.displayName)
                            .font(.misoBody)
                            .foregroundColor(.misoTextPrimary)

                        Spacer()

                        // Mood indicator
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Circle()
                                    .fill(i <= Int(avgMood.rounded()) ? Color.misoAccent : Color.misoBgSecondary)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Text(String(format: "%.1f", avgMood))
                            .font(.misoSubheadline)
                            .foregroundColor(.misoTextSecondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Not Enough Data View
    private var notEnoughDataView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.misoTextTertiary)

            Text("Not Enough Data Yet")
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text("Log at least 2 complete cycles to see insights and patterns about your health.")
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                ProgressItem(title: "Cycles logged", current: insightsViewModel.totalCycles, target: 2)
                ProgressItem(title: "Days tracked", current: insightsViewModel.totalDaysLogged, target: 14)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers
    private func moodEmoji(for value: Double) -> String {
        switch Int(value.rounded()) {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }

    private func energyEmoji(for value: Double) -> String {
        switch Int(value.rounded()) {
        case 1: return "🔋"
        case 2: return "🪫"
        case 3: return "⚡️"
        case 4: return "💪"
        case 5: return "🚀"
        default: return "⚡️"
        }
    }
}

// MARK: - Supporting Views
struct SummaryStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text(unit)
                .font(.misoCaption)
                .foregroundColor(.misoTextTertiary)

            Text(title)
                .font(.misoCaption)
                .foregroundColor(.misoTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }
}

struct ProgressItem: View {
    let title: String
    let current: Int
    let target: Int

    var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.misoSubheadline)
                    .foregroundColor(.misoTextPrimary)

                Spacer()

                Text("\(current)/\(target)")
                    .font(.misoCaption)
                    .foregroundColor(.misoTextSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.misoBgSecondary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.misoPrimary)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    MisoInsightsView(viewModel: CycleViewModel.preview)
}
