import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("currentUserData") private var currentUserData: Data = Data()
    @AppStorage("themePreference") var themePreference: String = "dark" {
        didSet { updateColorScheme() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false {
        didSet { handleNotificationsToggle() }
    }
    @AppStorage("hapticEnabled") var hapticEnabled: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    @Published var colorScheme: ColorScheme? = .dark
    @Published var currentUser: FSUser?
    @Published var showingAlert = false
    @Published var alertMessage = ""

    init() {
        updateColorScheme()
        if let user = try? JSONDecoder().decode(FSUser.self, from: currentUserData) {
            currentUser = user
        }
    }

    func updateColorScheme() {
        switch themePreference {
        case "light":  colorScheme = .light
        case "dark":   colorScheme = .dark
        default:       colorScheme = nil
        }
    }

    func loginDemo() {
        let demo = FSUser(id: "demo", name: "Demo User", email: "demo@focusshuffle.app")
        saveUser(demo)
        isLoggedIn = true
    }

    func loginWith(name: String, email: String) {
        let user = FSUser(name: name, email: email)
        saveUser(user)
        isLoggedIn = true
    }

    func logout() {
        currentUser = nil
        currentUserData = Data()
        isLoggedIn = false
    }

    func deleteAccount() {
        logout()
        hasCompletedOnboarding = false
    }

    private func saveUser(_ user: FSUser) {
        currentUser = user
        if let data = try? JSONEncoder().encode(user) {
            currentUserData = data
        }
    }

    func handleNotificationsToggle() {
        if notificationsEnabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    self.notificationsEnabled = granted
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    func scheduleFocusReminder(title: String, minutes: Int) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Focus Shuffle"
        content.body = "Time to focus on: \(title)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - TaskViewModel
class TaskViewModel: ObservableObject {
    @Published var tasks: [FSTask] = []
    @AppStorage("tasksData") private var tasksData: Data = Data()

    init() { load() }

    func load() {
        if let decoded = try? JSONDecoder().decode([FSTask].self, from: tasksData) {
            tasks = decoded
        } else {
            tasks = Self.demoTasks()
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(tasks) { tasksData = encoded }
    }

    func add(_ task: FSTask) { tasks.insert(task, at: 0); save() }

    func update(_ task: FSTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) { tasks[idx] = task; save() }
    }

    func delete(_ task: FSTask) { tasks.removeAll { $0.id == task.id }; save() }

    func toggle(_ task: FSTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            tasks[idx].completedAt = tasks[idx].isCompleted ? Date() : nil
            save()
        }
    }

    var pendingTasks: [FSTask] { tasks.filter { !$0.isCompleted } }
    var completedTasks: [FSTask] { tasks.filter { $0.isCompleted } }

    func shuffleItems(from selection: [FSTask]) -> [ShuffleItem] {
        selection.map {
            ShuffleItem(label: $0.title, subtitle: $0.category, priority: $0.priority, score: Double($0.priority.score))
        }.shuffled()
    }

    static func demoTasks() -> [FSTask] {
        [
            FSTask(title: "Launch MVP", description: "Ship the first version", priority: .critical, category: "Work", estimatedMinutes: 120),
            FSTask(title: "Review PRs", description: "Code review backlog", priority: .high, category: "Work", estimatedMinutes: 45),
            FSTask(title: "Team 1-on-1", description: "Weekly sync", priority: .medium, category: "Work", estimatedMinutes: 30),
            FSTask(title: "Update docs", description: "API documentation", priority: .low, category: "Work", estimatedMinutes: 60),
            FSTask(title: "Workout", description: "30-min run", priority: .medium, category: "Health", estimatedMinutes: 30),
        ]
    }
}

// MARK: - DecisionViewModel
class DecisionViewModel: ObservableObject {
    @Published var decisions: [FSDecision] = []
    @AppStorage("decisionsData") private var decisionsData: Data = Data()

    init() { load() }

    func load() {
        if let decoded = try? JSONDecoder().decode([FSDecision].self, from: decisionsData) {
            decisions = decoded
        } else {
            decisions = Self.demoDecisions()
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(decisions) { decisionsData = encoded }
    }

    func add(_ decision: FSDecision) { decisions.insert(decision, at: 0); save() }

    func update(_ decision: FSDecision) {
        if let idx = decisions.firstIndex(where: { $0.id == decision.id }) { decisions[idx] = decision; save() }
    }

    func delete(_ decision: FSDecision) { decisions.removeAll { $0.id == decision.id }; save() }

    /// Picks best option by weight score
    func recommend(for decision: FSDecision) -> String? {
        decision.options.max(by: { $0.weight < $1.weight })?.id
    }

    func shuffleItems(from decision: FSDecision) -> [ShuffleItem] {
        decision.options.map {
            ShuffleItem(
                id: $0.id,
                label: $0.title,
                subtitle: $0.description,
                priority: weightPriority($0.weight),
                score: $0.weight
            )
        }.shuffled()
    }

    private func weightPriority(_ w: Double) -> TaskPriority {
        switch w {
        case 4...5: return .critical
        case 3..<4: return .high
        case 2..<3: return .medium
        default:    return .low
        }
    }

    static func demoDecisions() -> [FSDecision] {
        let opts = [
            DecisionOption(title: "Option A", description: "Remote work setup", weight: 4.5, pros: ["Flexible hours", "No commute"], cons: ["Isolation"]),
            DecisionOption(title: "Option B", description: "Office hybrid", weight: 3.0, pros: ["Collaboration", "Networking"], cons: ["Commute"]),
            DecisionOption(title: "Option C", description: "Full office", weight: 2.0, pros: ["Team presence"], cons: ["Less flexible"])
        ]
        return [FSDecision(question: "How to structure my work week?", options: opts, notes: "Consider productivity and wellbeing")]
    }
}

// MARK: - AnalyticsViewModel
class AnalyticsViewModel: ObservableObject {
    @Published var snapshot: AnalyticsSnapshot

    init() {
        snapshot = AnalyticsSnapshot(
            totalDecisions: 28,
            successRate: 0.74,
            focusMinutes: 420,
            tasksCompleted: 47,
            streakDays: 7,
            weeklyData: [
                DayData(label: "Mon", tasks: 5, focusMin: 75),
                DayData(label: "Tue", tasks: 3, focusMin: 50),
                DayData(label: "Wed", tasks: 7, focusMin: 100),
                DayData(label: "Thu", tasks: 4, focusMin: 60),
                DayData(label: "Fri", tasks: 6, focusMin: 90),
                DayData(label: "Sat", tasks: 2, focusMin: 30),
                DayData(label: "Sun", tasks: 1, focusMin: 15),
            ]
        )
    }

    func recordDecision(wasSuccessful: Bool) {
        snapshot.totalDecisions += 1
        if wasSuccessful {
            let total = Double(snapshot.totalDecisions)
            snapshot.successRate = ((snapshot.successRate * (total - 1)) + 1.0) / total
        }
    }

    func recordFocusSession(_ minutes: Int) {
        snapshot.focusMinutes += minutes
        if var today = snapshot.weeklyData.last {
            today.focusMin += minutes
            snapshot.weeklyData[snapshot.weeklyData.count - 1] = today
        }
    }

    func recordTaskComplete() {
        snapshot.tasksCompleted += 1
        if var today = snapshot.weeklyData.last {
            today.tasks += 1
            snapshot.weeklyData[snapshot.weeklyData.count - 1] = today
        }
    }
}

// MARK: - FocusViewModel
class FocusViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var totalSeconds: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published var currentTask: String = ""
    @Published var selectedDuration: Int = 25
    @Published var sessions: [FocusSession] = []

    private var timer: Timer?
    private var sessionStart: Date?
    @AppStorage("focusSessionsData") private var sessionsData: Data = Data()

    init() { loadSessions() }

    var progress: Double { 1.0 - Double(remainingSeconds) / Double(totalSeconds) }
    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func start(task: String, minutes: Int) {
        currentTask = task
        selectedDuration = minutes
        totalSeconds = minutes * 60
        remainingSeconds = minutes * 60
        isRunning = true
        isPaused = false
        sessionStart = Date()
        scheduleTimer()
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
    }

    func resume() {
        isPaused = false
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        isRunning = false
        isPaused = false
        let elapsed = (totalSeconds - remainingSeconds) / 60
        if elapsed > 0 {
            let session = FocusSession(
                taskTitle: currentTask,
                durationMinutes: selectedDuration,
                completedMinutes: elapsed,
                startedAt: sessionStart ?? Date(),
                endedAt: Date(),
                wasCompleted: remainingSeconds == 0
            )
            sessions.insert(session, at: 0)
            saveSessions()
        }
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.timer?.invalidate()
                self.isRunning = false
                self.stop()
            }
        }
    }

    private func loadSessions() {
        if let decoded = try? JSONDecoder().decode([FocusSession].self, from: sessionsData) {
            sessions = decoded
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) { sessionsData = encoded }
    }
}

// MARK: - GamificationViewModel
class GamificationViewModel: ObservableObject {
    @AppStorage("currentStreak") var currentStreak: Int = 7
    @AppStorage("longestStreak") var longestStreak: Int = 14
    @AppStorage("totalPoints") var totalPoints: Int = 340
    @AppStorage("lastActiveDate") private var lastActiveDateStr: String = ""
    @Published var achievements: [Achievement] = []

    init() { setupAchievements() }

    func setupAchievements() {
        achievements = [
            Achievement(id: "first_shuffle", title: "First Shuffle", description: "Completed your first shuffle session", icon: "shuffle", color: .fsElectricBlue, isUnlocked: true, unlockedAt: Date()),
            Achievement(id: "focus_master", title: "Focus Master", description: "Completed 10 focus sessions", icon: "brain.head.profile", color: .fsViolet, isUnlocked: true, unlockedAt: Date()),
            Achievement(id: "decision_maker", title: "Decision Maker", description: "Made 25 decisions", icon: "checkmark.seal.fill", color: .fsGold, isUnlocked: true, unlockedAt: Date()),
            Achievement(id: "streak_7", title: "7-Day Streak", description: "7 days in a row", icon: "flame.fill", color: .fsMagenta, isUnlocked: true, unlockedAt: Date()),
            Achievement(id: "task_warrior", title: "Task Warrior", description: "Completed 50 tasks", icon: "bolt.fill", color: .fsGreen, isUnlocked: false, unlockedAt: nil),
            Achievement(id: "streak_30", title: "30-Day Streak", description: "30 days in a row", icon: "star.fill", color: .fsGold, isUnlocked: false, unlockedAt: nil),
        ]
    }

    func addPoints(_ pts: Int) {
        totalPoints += pts
        checkStreak()
    }

    func checkStreak() {
        let today = DateFormatter.shortDate.string(from: Date())
        if lastActiveDateStr != today {
            lastActiveDateStr = today
            currentStreak += 1
            if currentStreak > longestStreak { longestStreak = currentStreak }
        }
    }

    func unlockAchievement(id: String) {
        if let idx = achievements.firstIndex(where: { $0.id == id && !$0.isUnlocked }) {
            achievements[idx].isUnlocked = true
            achievements[idx].unlockedAt = Date()
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; return df
    }()
}
