import SwiftUI

@main
struct FocusShuffleApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var decisionVM = DecisionViewModel()
    @StateObject private var analyticsVM = AnalyticsViewModel()
    @StateObject private var focusVM = FocusViewModel()
    @StateObject private var gamificationVM = GamificationViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(taskVM)
                .environmentObject(decisionVM)
                .environmentObject(analyticsVM)
                .environmentObject(focusVM)
                .environmentObject(gamificationVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}
