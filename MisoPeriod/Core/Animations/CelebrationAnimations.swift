import SwiftUI

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @Binding var isActive: Bool

    let colors: [Color] = [.misoPrimary, .misoSecondary, .misoAccent, .misoPeriod, .orange, .yellow]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createParticles(in: geometry.size)

                    // Auto-dismiss after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isActive = false
                        particles.removeAll()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement() ?? .misoPrimary,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.2)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let rotation: Double
    let scale: CGFloat
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: 8 * particle.scale, height: 12 * particle.scale)
            .rotationEffect(.degrees(particle.rotation + rotation))
            .offset(x: particle.x + offsetX, y: particle.y + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    offsetY = UIScreen.main.bounds.height + 100
                    offsetX = CGFloat.random(in: -100...100)
                    rotation = Double.random(in: -360...360)
                }
                withAnimation(.easeIn(duration: 2.5).delay(0.5)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Pulse Animation Modifier
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Bounce Animation
struct BounceAnimation: ViewModifier {
    @State private var isBouncing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.1 : 1.0)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).repeatForever(autoreverses: true)) {
                    isBouncing = true
                }
            }
    }
}

// MARK: - Shimmer Animation
struct ShimmerAnimation: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(opacity)
                .onTapGesture {
                    dismiss()
                }

            // Celebration card
            VStack(spacing: 20) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 44))
                        .foregroundColor(color)
                }
                .modifier(BounceAnimation())

                Text(title)
                    .font(.misoTitle2)
                    .foregroundColor(.misoTextPrimary)

                Text(subtitle)
                    .font(.misoBody)
                    .foregroundColor(.misoTextSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                } label: {
                    Text("Yay!")
                        .font(.misoHeadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(color)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.misoBgCard)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .scaleEffect(scale)
            .opacity(opacity)

            // Confetti
            ConfettiView(isActive: $showConfetti)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
        }
    }
}

// MARK: - Streak Badge
struct StreakBadge: View {
    let streak: Int

    var streakColor: Color {
        switch streak {
        case 0..<3: return .misoTextTertiary
        case 3..<7: return .orange
        case 7..<14: return .misoPrimary
        case 14..<30: return .misoAccent
        default: return .misoSecondary
        }
    }

    var streakIcon: String {
        switch streak {
        case 0..<3: return "flame"
        case 3..<7: return "flame.fill"
        case 7..<14: return "flame.fill"
        case 14..<30: return "star.fill"
        default: return "crown.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streakIcon)
                .foregroundColor(streakColor)

            Text("\(streak)")
                .font(.misoHeadline)
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(streakColor.opacity(0.15))
        )
    }
}

// MARK: - Heart Animation
struct HeartAnimation: View {
    @State private var hearts: [HeartParticle] = []
    @Binding var isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(hearts) { heart in
                    Image(systemName: "heart.fill")
                        .font(.system(size: heart.size))
                        .foregroundColor(heart.color)
                        .position(x: heart.x, y: heart.y)
                        .opacity(heart.opacity)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createHearts(in: geometry.size)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isActive = false
                        hearts.removeAll()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createHearts(in size: CGSize) {
        let colors: [Color] = [.misoPrimary, .pink, .red.opacity(0.8)]

        for i in 0..<15 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                let heart = HeartParticle(
                    x: size.width / 2 + CGFloat.random(in: -50...50),
                    y: size.height,
                    size: CGFloat.random(in: 16...32),
                    color: colors.randomElement() ?? .misoPrimary,
                    opacity: 1.0
                )

                withAnimation(.easeOut(duration: 1.5)) {
                    hearts.append(heart)
                }

                // Animate upward
                withAnimation(.easeOut(duration: 1.5)) {
                    if let index = hearts.firstIndex(where: { $0.id == heart.id }) {
                        hearts[index].y = CGFloat.random(in: 0...size.height * 0.3)
                        hearts[index].x += CGFloat.random(in: -80...80)
                        hearts[index].opacity = 0
                    }
                }
            }
        }
    }
}

struct HeartParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    var opacity: Double
}

// MARK: - View Extensions
extension View {
    func pulseAnimation(color: Color = .misoPrimary) -> some View {
        modifier(PulseAnimation(color: color))
    }

    func bounceAnimation() -> some View {
        modifier(BounceAnimation())
    }

    func shimmerAnimation() -> some View {
        modifier(ShimmerAnimation())
    }

    func celebrationOverlay(
        isShowing: Binding<Bool>,
        title: String,
        subtitle: String,
        icon: String = "star.fill",
        color: Color = .misoPrimary
    ) -> some View {
        ZStack {
            self

            if isShowing.wrappedValue {
                CelebrationOverlay(
                    isShowing: isShowing,
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    color: color
                )
            }
        }
    }
}
