import SwiftUI

// MARK: - Root
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else if !appState.isLoggedIn {
                AuthView()
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
            } else {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSplash)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isLoggedIn)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation { showSplash = false }
            }
        }
    }
}

// MARK: - Splash
struct SplashView: View {
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var ring1Scale: CGFloat = 0.6
    @State private var ring2Scale: CGFloat = 0.6
    @State private var thimbleRotation: Double = 0
    @State private var subtitle = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // Glow rings
                    Circle()
                        .stroke(Color.fsViolet.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ring1Scale)
                        .blur(radius: 4)
                    Circle()
                        .stroke(Color.fsCyan.opacity(0.2), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(ring2Scale)
                        .blur(radius: 6)

                    // Thimbles
                    HStack(spacing: -8) {
                        ThimbleSplashIcon(color: .fsElectricBlue, offset: -10)
                            .rotationEffect(.degrees(thimbleRotation))
                        ThimbleSplashIcon(color: .fsViolet, offset: 0)
                        ThimbleSplashIcon(color: .fsCyan, offset: 10)
                            .rotationEffect(.degrees(-thimbleRotation))
                    }
                    .shadow(color: .fsViolet.opacity(0.5), radius: CGFloat(glowIntensity * 20))
                }
                .scaleEffect(scale)
                .opacity(opacity)

                Spacer().frame(height: 32)

                VStack(spacing: 8) {
                    Text("Focus Shuffle")
                        .font(FSFont.display(36))
                        .foregroundStyle(LinearGradient(
                            colors: [.fsCyan, .fsElectricBlue, .fsViolet],
                            startPoint: .leading, endPoint: .trailing))
                    if subtitle {
                        Text("Train Attention. Make Better Decisions.")
                            .font(FSFont.body(15))
                            .foregroundColor(.fsTextSecond)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .opacity(opacity)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0; opacity = 1.0; glowIntensity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).delay(0.3).repeatForever(autoreverses: true)) {
                ring1Scale = 1.1; ring2Scale = 1.05
            }
            withAnimation(.easeInOut(duration: 2.0).delay(0.5).repeatForever(autoreverses: true)) {
                thimbleRotation = 15
            }
            withAnimation(.spring(response: 0.5).delay(1.0)) {
                subtitle = true
            }
        }
    }
}

struct ThimbleSplashIcon: View {
    let color: Color
    let offset: CGFloat
    var body: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(
                    colors: [color.opacity(0.9), color.opacity(0.4)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 32, height: 50)
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
                .offset(y: -14)
        }
        .offset(y: offset)
    }
}

// MARK: - Auth View
struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var email = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMsg = ""

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 60)

                    // Logo
                    VStack(spacing: 12) {
                        HStack(spacing: -6) {
                            ThimbleSplashIcon(color: .fsElectricBlue, offset: -4)
                            ThimbleSplashIcon(color: .fsViolet, offset: 0)
                            ThimbleSplashIcon(color: .fsCyan, offset: -4)
                        }
                        .frame(height: 60)
                        Text("Focus Shuffle")
                            .font(FSFont.display(30))
                            .foregroundStyle(LinearGradient(
                                colors: [.fsCyan, .fsViolet],
                                startPoint: .leading, endPoint: .trailing))
                    }

                    // Card
                    FSCard {
                        VStack(spacing: 20) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(FSFont.heading(22))
                                .foregroundColor(.fsTextPrimary)

                            if isSignUp {
                                FSTextField(title: "Your Name", text: $name, icon: "person.fill")
                            }
                            FSTextField(title: "Email", text: $email, icon: "envelope.fill", keyboard: .emailAddress)

                            if showError {
                                Text(errorMsg)
                                    .font(FSFont.caption(13))
                                    .foregroundColor(.fsMagenta)
                            }

                            FSPrimaryButton(isSignUp ? "Create Account" : "Sign In", icon: "arrow.right") {
                                handleAuth()
                            }

                            Button(action: { isSignUp.toggle() }) {
                                Text(isSignUp ? "Already have an account? Sign in" : "New here? Create account")
                                    .font(FSFont.caption(14))
                                    .foregroundColor(.fsElectricBlue)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Demo
                    VStack(spacing: 12) {
                        HStack {
                            Rectangle().fill(Color.fsTextMuted).frame(height: 1)
                            Text("or").font(FSFont.caption(13)).foregroundColor(.fsTextMuted)
                            Rectangle().fill(Color.fsTextMuted).frame(height: 1)
                        }
                        .padding(.horizontal, 24)

                        Button(action: { appState.loginDemo() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text("Continue with Demo Account")
                                    .font(FSFont.heading(15))
                            }
                            .foregroundColor(.fsDeepNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(LinearGradient.fsGoldGradient)
                            .cornerRadius(16)
                            .shadow(color: .fsGold.opacity(0.5), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
    }

    func handleAuth() {
        if isSignUp {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                showError = true; errorMsg = "Please enter your name"; return
            }
        }
        guard email.contains("@") else {
            showError = true; errorMsg = "Please enter a valid email"; return
        }
        showError = false
        appState.loginWith(name: isSignUp ? name : email.components(separatedBy: "@").first ?? "User", email: email)
    }
}

struct FSTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.fsElectricBlue)
                .frame(width: 20)
            TextField(title, text: $text)
                .font(FSFont.body(15))
                .foregroundColor(.fsTextPrimary)
                .keyboardType(keyboard)
                .autocapitalization(.none)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.fsDeepNavy.opacity(0.6))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fsElectricBlue.opacity(0.3), lineWidth: 1))
    }
}
