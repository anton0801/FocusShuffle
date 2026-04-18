import SwiftUI
import Foundation

// MARK: - User
struct FSUser: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var email: String
    var avatarInitials: String { String(name.prefix(2)).uppercased() }
}

// MARK: - Task Priority
enum TaskPriority: String, Codable, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var label: String { rawValue }
    var score: Int {
        switch self { case .critical: return 4; case .high: return 3; case .medium: return 2; case .low: return 1 }
    }
    var color: Color {
        switch self {
        case .critical: return .fsMagenta
        case .high:     return Color(hex: "#FF6B35")
        case .medium:   return .fsGold
        case .low:      return .fsGreen
        }
    }
    var icon: String {
        switch self {
        case .critical: return "flame.fill"
        case .high:     return "arrow.up.circle.fill"
        case .medium:   return "minus.circle.fill"
        case .low:      return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Task
struct FSTask: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var description: String
    var priority: TaskPriority
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    var category: String
    var estimatedMinutes: Int
    var notes: String = ""
}

// MARK: - Decision Option
struct DecisionOption: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var description: String
    var weight: Double = 1.0   // 1..5
    var pros: [String] = []
    var cons: [String] = []
}

// MARK: - Decision
struct FSDecision: Codable, Identifiable {
    var id: String = UUID().uuidString
    var question: String
    var options: [DecisionOption]
    var chosenOptionId: String?
    var recommendedOptionId: String?
    var createdAt: Date = Date()
    var notes: String = ""

    var recommendedOption: DecisionOption? {
        guard let rid = recommendedOptionId else { return nil }
        return options.first { $0.id == rid }
    }
    var chosenOption: DecisionOption? {
        guard let cid = chosenOptionId else { return nil }
        return options.first { $0.id == cid }
    }
}

// MARK: - Focus Session
struct FocusSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var taskId: String?
    var taskTitle: String
    var durationMinutes: Int
    var completedMinutes: Int
    var startedAt: Date
    var endedAt: Date?
    var wasCompleted: Bool = false
}

// MARK: - Note
struct FSNote: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var content: String
    var linkedDecisionId: String?
    var linkedTaskId: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var tags: [String] = []
}

// MARK: - Achievement
struct Achievement: Identifiable {
    var id: String
    var title: String
    var description: String
    var icon: String
    var color: Color
    var isUnlocked: Bool
    var unlockedAt: Date?
}

// MARK: - Shuffle Item (used in Shuffle Mode)
struct ShuffleItem: Identifiable {
    var id: String = UUID().uuidString
    var label: String
    var subtitle: String
    var priority: TaskPriority
    var score: Double
}

// MARK: - Analytics Snapshot
struct AnalyticsSnapshot {
    var totalDecisions: Int
    var successRate: Double      // 0..1
    var focusMinutes: Int
    var tasksCompleted: Int
    var streakDays: Int
    var weeklyData: [DayData]
}

struct DayData: Identifiable {
    var id = UUID()
    var label: String
    var tasks: Int
    var focusMin: Int
}
