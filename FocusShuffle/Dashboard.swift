import SwiftUI

// MARK: - Main Tab
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView().tag(0)
                ShuffleModeContainerView().tag(1)
                FocusModeView().tag(2)
                AnalyticsView().tag(3)
                ProfileView().tag(4)
            }
            .tabViewStyle(DefaultTabViewStyle())

            FSTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct FSTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, label: String)] = [
        ("house.fill",         "Home"),
        ("shuffle",            "Shuffle"),
        ("timer",              "Focus"),
        ("chart.bar.fill",     "Stats"),
        ("person.fill",        "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedTab = i } }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: selectedTab == i ? 22 : 20, weight: .semibold))
                            .foregroundColor(selectedTab == i ? .fsCyan : .fsTextMuted)
                            .scaleEffect(selectedTab == i ? 1.15 : 1.0)
                            .shadow(color: selectedTab == i ? .fsCyan.opacity(0.7) : .clear, radius: 8)
                        Text(tabs[i].label)
                            .font(FSFont.caption(10))
                            .foregroundColor(selectedTab == i ? .fsCyan : .fsTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.fsNavy.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.07), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var decisionVM: DecisionViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAddTask = false
    @State private var showAllTasks = false
    @State private var animateCards = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(timeGreeting())")
                                .font(FSFont.body(14))
                                .foregroundColor(.fsTextSecond)
                            Text(appState.currentUser?.name ?? "Focuser")
                                .font(FSFont.display(26))
                                .foregroundColor(.fsTextPrimary)
                        }
                        Spacer()
                        StreakBadge(streak: gamificationVM.currentStreak)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Stats row
                    HStack(spacing: 12) {
                        MiniStatCard(value: "\(taskVM.pendingTasks.count)", label: "Tasks", color: .fsElectricBlue)
                        MiniStatCard(value: "\(decisionVM.decisions.count)", label: "Decisions", color: .fsViolet)
                        MiniStatCard(value: "\(gamificationVM.totalPoints)", label: "Points", color: .fsGold)
                    }
                    .padding(.horizontal, 20)

                    // Priority Queue
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader("Priority Queue", action: { showAllTasks = true }, actionLabel: "See all")

                        if taskVM.pendingTasks.isEmpty {
                            EmptyStateCard(message: "No tasks yet. Add one!", icon: "checkmark.circle.fill")
                        } else {
                            ForEach(taskVM.pendingTasks.prefix(3)) { task in
                                TaskRowCard(task: task)
                                    .scaleEffect(animateCards ? 1 : 0.95)
                                    .opacity(animateCards ? 1 : 0)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Recent Decisions
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader("Recent Decisions", action: nil, actionLabel: nil)
                        if decisionVM.decisions.isEmpty {
                            EmptyStateCard(message: "No decisions yet", icon: "lightbulb.fill")
                        } else {
                            ForEach(decisionVM.decisions.prefix(2)) { decision in
                                DecisionRowCard(decision: decision)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 100)
                }
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(LinearGradient.fsPrimary)
                            .clipShape(Circle())
                            .shadow(color: .fsElectricBlue.opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet()
        }
        .sheet(isPresented: $showAllTasks) {
            TaskListView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateCards = true
            }
        }
    }

    func timeGreeting() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Morning,"
        case 12..<17: return "Afternoon,"
        case 17..<21: return "Evening,"
        default:      return "Night,"
        }
    }
}

// MARK: - Dashboard sub-components
struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        FSCard(padding: 16) {
            VStack(spacing: 4) {
                Text(value)
                    .font(FSFont.display(24))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 4)
                Text(label)
                    .font(FSFont.caption(12))
                    .foregroundColor(.fsTextSecond)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct StreakBadge: View {
    let streak: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundColor(.fsMagenta)
                .font(.system(size: 16))
            Text("\(streak)")
                .font(FSFont.heading(16))
                .foregroundColor(.fsTextPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.fsMagenta.opacity(0.15))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.fsMagenta.opacity(0.3), lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(_ title: String, action: (() -> Void)? = nil, actionLabel: String? = nil) {
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        HStack {
            Text(title)
                .font(FSFont.heading(18))
                .foregroundColor(.fsTextPrimary)
            Spacer()
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(FSFont.caption(13))
                        .foregroundColor(.fsElectricBlue)
                }
            }
        }
    }
}

struct TaskRowCard: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var gamificationVM: GamificationViewModel
    let task: FSTask

    var body: some View {
        FSCard(padding: 16) {
            HStack(spacing: 14) {
                Button(action: {
                    taskVM.toggle(task)
                    gamificationVM.addPoints(10)
                }) {
                    ZStack {
                        Circle()
                            .stroke(task.priority.color, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if task.isCompleted {
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(FSFont.body(15))
                        .foregroundColor(task.isCompleted ? .fsTextMuted : .fsTextPrimary)
                        .strikethrough(task.isCompleted)
                    HStack(spacing: 8) {
                        PriorityBadge(priority: task.priority)
                        Text(task.category)
                            .font(FSFont.caption(12))
                            .foregroundColor(.fsTextMuted)
                    }
                }
                Spacer()
                Text("\(task.estimatedMinutes)m")
                    .font(FSFont.mono(12))
                    .foregroundColor(.fsTextMuted)
            }
        }
    }
}

struct DecisionRowCard: View {
    let decision: FSDecision

    var body: some View {
        FSCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.fsViolet.opacity(0.2))
                        .frame(width: 42, height: 42)
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.fsViolet)
                        .font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.question)
                        .font(FSFont.body(14))
                        .foregroundColor(.fsTextPrimary)
                        .lineLimit(2)
                    Text("\(decision.options.count) options")
                        .font(FSFont.caption(12))
                        .foregroundColor(.fsTextSecond)
                }
                Spacer()
                if let rec = decision.recommendedOption {
                    Text(rec.title)
                        .font(FSFont.caption(11))
                        .foregroundColor(.fsGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.fsGreen.opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct EmptyStateCard: View {
    let message: String
    let icon: String
    var body: some View {
        FSCard {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.fsTextMuted)
                Text(message)
                    .font(FSFont.body(14))
                    .foregroundColor(.fsTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
