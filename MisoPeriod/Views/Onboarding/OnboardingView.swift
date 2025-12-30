import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: CycleViewModel
    @Binding var isPresented: Bool

    @State private var currentPage = 0
    @State private var cycleLength = 28
    @State private var periodLength = 5
    @State private var lastPeriodDate = Date()
    @State private var isCompleting = false

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.misoPrimary.opacity(0.1), Color.misoBgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                pageIndicator
                    .padding(.top, 20)

                // Content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    cycleLengthPage.tag(1)
                    periodLengthPage.tag(2)
                    lastPeriodPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.misoPrimary : Color.misoPrimary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon/illustration
            ZStack {
                Circle()
                    .fill(Color.misoPrimary.opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.misoPrimary, .misoSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 16) {
                Text("Welcome to MisoPeriod")
                    .font(.misoLargeTitle)
                    .foregroundColor(.misoTextPrimary)

                Text("Your personal cycle companion.\nTrack, understand, and embrace your rhythm.")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Privacy note
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.misoAccent)

                Text("All your data stays on your device")
                    .font(.misoSubheadline)
                    .foregroundColor(.misoTextSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.misoAccent.opacity(0.1))
            )

            Spacer()
        }
        .padding()
    }

    // MARK: - Cycle Length Page
    private var cycleLengthPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.misoPrimary)

            VStack(spacing: 12) {
                Text("How long is your cycle?")
                    .font(.misoTitle2)
                    .foregroundColor(.misoTextPrimary)

                Text("The average cycle is 28 days, but it can range from 21-35 days.")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Cycle length picker
            VStack(spacing: 8) {
                Text("\(cycleLength)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.misoPrimary)

                Text("days")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextSecondary)
            }

            // Slider
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { Double(cycleLength) },
                    set: { cycleLength = Int($0) }
                ), in: 21...40, step: 1)
                .tint(.misoPrimary)
                .padding(.horizontal, 32)

                HStack {
                    Text("21 days")
                    Spacer()
                    Text("40 days")
                }
                .font(.misoCaption)
                .foregroundColor(.misoTextTertiary)
                .padding(.horizontal, 32)
            }

            // Quick select buttons
            HStack(spacing: 12) {
                QuickSelectButton(value: 26, selected: cycleLength == 26) { cycleLength = 26 }
                QuickSelectButton(value: 28, selected: cycleLength == 28) { cycleLength = 28 }
                QuickSelectButton(value: 30, selected: cycleLength == 30) { cycleLength = 30 }
                QuickSelectButton(value: 32, selected: cycleLength == 32) { cycleLength = 32 }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Period Length Page
    private var periodLengthPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "drop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.misoPeriod)

            VStack(spacing: 12) {
                Text("How long is your period?")
                    .font(.misoTitle2)
                    .foregroundColor(.misoTextPrimary)

                Text("Most periods last 3-7 days.")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Period length picker
            VStack(spacing: 8) {
                Text("\(periodLength)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.misoPeriod)

                Text("days")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextSecondary)
            }

            // Period length buttons
            HStack(spacing: 16) {
                ForEach(3...7, id: \.self) { days in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            periodLength = days
                        }
                    } label: {
                        VStack(spacing: 4) {
                            // Drop indicators
                            HStack(spacing: 2) {
                                ForEach(0..<min(days - 2, 4), id: \.self) { _ in
                                    Image(systemName: "drop.fill")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(periodLength == days ? .white : .misoPeriod)

                            Text("\(days)")
                                .font(.misoHeadline)
                                .foregroundColor(periodLength == days ? .white : .misoTextPrimary)
                        }
                        .frame(width: 50, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(periodLength == days ? Color.misoPeriod : Color.misoBgCard)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Last Period Page
    private var lastPeriodPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.misoSecondary)

            VStack(spacing: 12) {
                Text("When did your last period start?")
                    .font(.misoTitle2)
                    .foregroundColor(.misoTextPrimary)

                Text("This helps us predict your next cycle.")
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Date picker
            VStack(spacing: 16) {
                DatePicker(
                    "Last period start",
                    selection: $lastPeriodDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.misoPrimary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.misoBgCard)
                )

                // Days ago indicator
                let daysAgo = lastPeriodDate.daysBetween(Date())
                if daysAgo > 0 {
                    Text("\(daysAgo) days ago")
                        .font(.misoSubheadline)
                        .foregroundColor(.misoTextSecondary)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if currentPage > 0 {
                Button {
                    withAnimation {
                        currentPage -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.misoBgCard)
                    )
                }
            }

            // Next/Finish button
            Button {
                if currentPage < totalPages - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                        if currentPage < totalPages - 1 {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.misoHeadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.misoPrimary)
                )
            }
            .disabled(isCompleting)
        }
    }

    // MARK: - Actions
    private func completeOnboarding() {
        isCompleting = true

        Task {
            await viewModel.completeOnboarding(
                cycleLength: cycleLength,
                periodLength: periodLength,
                lastPeriodStart: lastPeriodDate
            )

            await MainActor.run {
                isCompleting = false
                isPresented = false
            }
        }
    }
}

// MARK: - Quick Select Button
struct QuickSelectButton: View {
    let value: Int
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.misoSubheadline)
                .foregroundColor(selected ? .white : .misoTextPrimary)
                .frame(width: 50, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color.misoPrimary : Color.misoBgCard)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView(viewModel: CycleViewModel.preview, isPresented: .constant(true))
}
