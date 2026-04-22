import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let fsDeepNavy     = Color(hex: "#0A0E1A")
    static let fsNavy         = Color(hex: "#0F1628")
    static let fsDarkBlue     = Color(hex: "#141C35")
    static let fsCardBg       = Color(hex: "#1A2240")
    static let fsCardBg2      = Color(hex: "#1E2850")

    // Accent / Glow
    static let fsElectricBlue = Color(hex: "#3A7BFF")
    static let fsViolet       = Color(hex: "#7B4FFF")
    static let fsCyan         = Color(hex: "#00D4FF")
    static let fsMagenta      = Color(hex: "#FF3D9A")
    static let fsGold         = Color(hex: "#FFB800")
    static let fsGreen        = Color(hex: "#00E5A0")

    // Text
    static let fsTextPrimary  = Color(hex: "#EAEEF8")
    static let fsTextSecond   = Color(hex: "#8A95B4")
    static let fsTextMuted    = Color(hex: "#4A5580")

    // Thimble metallic
    static let fsThimbleLight = Color(hex: "#B0C4DE")
    static let fsThimbleMid   = Color(hex: "#6A8AAA")
    static let fsThimbleDark  = Color(hex: "#2A3A55")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let fsBackground = LinearGradient(
        colors: [.fsDeepNavy, .fsNavy, Color(hex: "#0D1230")],
        startPoint: .top, endPoint: .bottom)

    static let fsCard = LinearGradient(
        colors: [.fsCardBg, .fsCardBg2],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let fsPrimary = LinearGradient(
        colors: [.fsElectricBlue, .fsViolet],
        startPoint: .leading, endPoint: .trailing)

    static let fsCyanViolet = LinearGradient(
        colors: [.fsCyan, .fsViolet],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let fsGoldGradient = LinearGradient(
        colors: [Color(hex: "#FFD700"), Color(hex: "#FF8C00")],
        startPoint: .top, endPoint: .bottom)

    static let fsGreenGradient = LinearGradient(
        colors: [.fsGreen, Color(hex: "#00A870")],
        startPoint: .top, endPoint: .bottom)

    static let fsThimble = LinearGradient(
        colors: [.fsThimbleLight, .fsThimbleMid, .fsThimbleDark, .fsThimbleMid],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Typography
struct FSFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct FocusShuffleNotificationView: View {
    let viewModel: FocusShuffleViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("bg_for_notifications")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.6)
                
                VStack(spacing: 12) {
                    Spacer()
                    
                    Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    
                    Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    
                    actionButtons
                }
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.authorize()
            } label: {
                Text("Yes, I Want Bonuses!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(hex: "#00ABFF")
                    )
                    .cornerRadius(12)
                
            }
            .padding(.horizontal, 24)
            
            Button {
                viewModel.skip()
            } label: {
                Text("Skip")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
}

struct FSPrimaryButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void

    init(_ title: String, icon: String? = nil, gradient: LinearGradient = .fsPrimary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(FSFont.body(16))
                }
                Text(title)
                    .font(FSFont.heading(16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(gradient)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .fsElectricBlue.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = false } })
    }
}

struct FSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(FSFont.body(15))
                }
                Text(title)
                    .font(FSFont.body(15))
            }
            .foregroundColor(.fsTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.fsCardBg.opacity(0.8))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.fsElectricBlue.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = false } })
    }
}

// MARK: - Card
struct FSCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(LinearGradient.fsCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Glowing Circle
struct GlowCircle: View {
    let color: Color
    let size: CGFloat
    let blur: CGFloat

    var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: size, height: size)
            .blur(radius: blur)
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.label)
            .font(FSFont.caption(11))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priority.color.opacity(0.85))
            .cornerRadius(6)
    }
}

// MARK: - Shimmer
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: .init(x: phase - 0.3, y: 0.5),
                    endPoint: .init(x: phase + 0.3, y: 0.5)
                )
                .blendMode(.screen)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Background
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient.fsBackground
                .ignoresSafeArea()
            GlowCircle(color: .fsViolet, size: 300, blur: 120)
                .offset(x: -100, y: -200)
            GlowCircle(color: .fsElectricBlue, size: 250, blur: 100)
                .offset(x: 150, y: 300)
        }
    }
}
