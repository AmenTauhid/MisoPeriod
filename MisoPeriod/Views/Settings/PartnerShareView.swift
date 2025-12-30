import SwiftUI
import CoreImage.CIFilterBuiltins

struct PartnerShareView: View {
    @ObservedObject var viewModel: CycleViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var qrImage: UIImage?
    @State private var showingShareSheet = false
    @State private var shareText = ""

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // QR Code
                        qrCodeSection

                        // Summary card
                        summaryCard

                        // Share options
                        shareOptionsSection

                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Share with Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.misoPrimary)
                }
            }
            .onAppear {
                generateQRCode()
                generateShareText()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.misoPrimary, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Share Your Cycle")
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text("Let your partner know what to expect.\nNo account needed - just scan!")
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - QR Code Section
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10)
            } else {
                ProgressView()
                    .frame(width: 200, height: 200)
            }

            Text("Scan to view cycle summary")
                .font(.misoCaption)
                .foregroundColor(.misoTextTertiary)
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.misoAccent)
                Text("What's Shared")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
            }

            VStack(spacing: 12) {
                SummaryRow(
                    icon: "calendar",
                    title: "Current cycle day",
                    value: "Day \(viewModel.cycleDay)"
                )

                SummaryRow(
                    icon: viewModel.currentPhase.icon,
                    title: "Current phase",
                    value: viewModel.currentPhase.displayName
                )

                if let daysUntil = viewModel.daysUntilPeriod, daysUntil > 0 {
                    SummaryRow(
                        icon: "drop.fill",
                        title: "Next period",
                        value: "in \(daysUntil) days"
                    )
                }

                if viewModel.isInFertileWindow {
                    SummaryRow(
                        icon: "leaf.fill",
                        title: "Fertility",
                        value: "Fertile window active"
                    )
                }
            }

            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.misoTextTertiary)

                Text("No personal data or health details are shared")
                    .font(.misoCaption)
                    .foregroundColor(.misoTextTertiary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Share Options
    private var shareOptionsSection: some View {
        VStack(spacing: 12) {
            // Share as text
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Summary")
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

            // Copy to clipboard
            Button {
                UIPasteboard.general.string = shareText
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy to Clipboard")
                }
                .font(.misoHeadline)
                .foregroundColor(.misoPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.misoPrimary, lineWidth: 2)
                )
            }
        }
    }

    // MARK: - QR Code Generation
    private func generateQRCode() {
        let summary = createSummaryForQR()

        filter.message = Data(summary.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgImage)
            }
        }
    }

    private func createSummaryForQR() -> String {
        var summary = "MisoPeriod\n"
        summary += "Day: \(viewModel.cycleDay)\n"
        summary += "Phase: \(viewModel.currentPhase.displayName)\n"

        if let daysUntil = viewModel.daysUntilPeriod, daysUntil > 0 {
            summary += "Next: \(daysUntil)d\n"
        }

        if viewModel.isInFertileWindow {
            summary += "Fertile: Yes"
        }

        return summary
    }

    private func generateShareText() {
        var text = "Hey! Here's my cycle update:\n\n"
        text += "Currently on Day \(viewModel.cycleDay) (\(viewModel.currentPhase.displayName) phase)\n"

        if let daysUntil = viewModel.daysUntilPeriod, daysUntil > 0 {
            text += "Next period expected in \(daysUntil) days\n"
        } else if viewModel.isOnPeriod {
            text += "Currently on my period\n"
        }

        if viewModel.isInFertileWindow {
            text += "Fertile window is active\n"
        }

        text += "\n\(viewModel.currentPhase.partnerTip)"
        text += "\n\nSent from MisoPeriod"

        shareText = text
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.misoAccent)
                .frame(width: 24)

            Text(title)
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)

            Spacer()

            Text(value)
                .font(.misoSubheadline)
                .foregroundColor(.misoTextPrimary)
        }
    }
}

// MARK: - CyclePhase Partner Tips Extension
extension CyclePhase {
    var partnerTip: String {
        switch self {
        case .menstrual:
            return "Tip: Extra comfort and understanding goes a long way right now."
        case .follicular:
            return "Tip: Energy is building up - great time for activities together!"
        case .ovulation:
            return "Tip: Peak energy and mood - perfect for date nights!"
        case .luteal:
            return "Tip: Might need more rest and patience during this time."
        }
    }
}

#Preview {
    PartnerShareView(viewModel: CycleViewModel.preview)
}
