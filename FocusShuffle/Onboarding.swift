import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Focus on What\nMatters",
            subtitle: "Three thimbles. One priority. Infinite clarity.",
            icon: "target",
            accentColor: .fsElectricBlue,
            feature: .thimbles
        ),
        OnboardingPage(
            title: "Train Your\nAttention",
            subtitle: "Shuffle your options and sharpen decision-making daily.",
            icon: "brain.head.profile",
            accentColor: .fsViolet,
            feature: .shuffle
        ),
        OnboardingPage(
            title: "Pick Smarter\nEvery Day",
            subtitle: "Let AI-weighted priorities guide your best choices.",
            icon: "checkmark.seal.fill",
            accentColor: .fsCyan,
            feature: .decision
        ),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: finish) {
                            Text("Skip")
                                .font(FSFont.body(15))
                                .foregroundColor(.fsTextSecond)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.top, 8)

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { idx in
                        OnboardingPageView(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Dots + Button
                VStack(spacing: 28) {
                    HStack(spacing: 10) {
                        ForEach(pages.indices, id: \.self) { idx in
                            Capsule()
                                .fill(idx == currentPage ? Color.fsElectricBlue : Color.fsTextMuted.opacity(0.4))
                                .frame(width: idx == currentPage ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    FSPrimaryButton(currentPage < pages.count - 1 ? "Next" : "Get Started", icon: currentPage < pages.count - 1 ? "arrow.right" : "checkmark") {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            finish()
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }

    func finish() {
        appState.hasCompletedOnboarding = true
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let feature: OnboardingFeature
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image("error_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 2)
                    .opacity(0.8)
                
                Image("error_alert")
                    .resizable()
                    .frame(width: 220, height: 180)
            }
        }
        .ignoresSafeArea()
    }
}

enum OnboardingFeature { case thimbles, shuffle, decision }

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false
    @State private var shuffleOffset: [CGFloat] = [0, 0, 0]
    @State private var thimbleScale: [CGFloat] = [1, 1, 1]
    @State private var selectedIndex: Int? = nil
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Illustration
            ZStack {
                GlowCircle(color: page.accentColor, size: 220, blur: 80)
                    .opacity(glowPulse ? 1 : 0.6)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                switch page.feature {
                case .thimbles: ThimblesIllustration(accentColor: page.accentColor, scales: $thimbleScale)
                case .shuffle:  ShuffleIllustration(offsets: $shuffleOffset)
                case .decision: DecisionIllustration(selectedIndex: $selectedIndex)
                }
            }
            .frame(height: 200)

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(FSFont.display(34))
                    .foregroundColor(.fsTextPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Text(page.subtitle)
                    .font(FSFont.body(16))
                    .foregroundColor(.fsTextSecond)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
            glowPulse = true
            startFeatureAnimation()
        }
        .onDisappear { appeared = false }
    }

    func startFeatureAnimation() {
        switch page.feature {
        case .thimbles:
            for i in 0..<3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(i) * 0.15)) {
                    thimbleScale[i] = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { thimbleScale[i] = 1.0 }
                }
            }
        case .shuffle:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { animateShuffle() }
        case .decision:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { selectedIndex = 0 }
            }
        }
    }

    func animateShuffle() {
        let moves: [[CGFloat]] = [[-40, 60, -20], [30, -50, 20], [-10, -10, -10]]
        for (i, move) in moves.enumerated() {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.18)) {
                shuffleOffset = move
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { shuffleOffset = [0, 0, 0] }
        }
    }
}

struct ThimblesIllustration: View {
    let accentColor: Color
    @Binding var scales: [CGFloat]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { i in
                ThimbleView(color: accentColor.opacity(1 - Double(i) * 0.2), hasBall: i == 1, label: ["Priority", "Focus", "Decision"][i])
                    .scaleEffect(scales[i])
            }
        }
    }
}

struct ShuffleIllustration: View {
    @Binding var offsets: [CGFloat]
    let colors: [Color] = [.fsElectricBlue, .fsViolet, .fsCyan]

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { i in
                ThimbleView(color: colors[i], hasBall: false, label: "")
                    .offset(x: offsets.indices.contains(i) ? offsets[i] : 0)
            }
        }
    }
}

struct DecisionIllustration: View {
    @Binding var selectedIndex: Int?
    let labels = ["Option A", "Option B", "Option C"]

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { i in
                ThimbleView(
                    color: selectedIndex == i ? .fsGold : .fsThimbleMid,
                    hasBall: selectedIndex == i,
                    label: labels[i]
                )
                .scaleEffect(selectedIndex == i ? 1.15 : 1.0)
                .shadow(color: selectedIndex == i ? Color.fsGold.opacity(0.6) : .clear, radius: 16)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedIndex)
            }
        }
    }
}

// MARK: - Thimble Component
struct ThimbleView: View {
    let color: Color
    let hasBall: Bool
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Body
                ZStack {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [color.opacity(0.9), color.opacity(0.5), color.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    // Shine
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.3), .clear],
                            startPoint: .topLeading, endPoint: .center))
                        .padding(3)
                    // Dots pattern
                    VStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 3, height: 3)
                                }
                            }
                        }
                    }
                    .offset(y: 4)
                }
                .frame(width: 52, height: 70)

                // Ball
                if hasBall {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.fsGold, Color(hex: "#FF8C00")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 18, height: 18)
                        .shadow(color: .fsGold.opacity(0.8), radius: 8)
                        .offset(y: 20)
                }
            }
            .frame(height: 80)

            if !label.isEmpty {
                Text(label)
                    .font(FSFont.caption(11))
                    .foregroundColor(.fsTextSecond)
            }
        }
    }
}
