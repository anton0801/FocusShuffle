import Foundation
import Combine

@MainActor
final class FocusShuffleViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let engine: FocusShuffleEngine
    private var timeoutJob: Task<Void, Never>?
    
    init(engine: FocusShuffleEngine) {
        self.engine = engine
    }
    
    func startup() {
        Task {
            await engine.startup()
            scheduleTimeout()
        }
    }
    
    func handleConversionData(_ data: [String: Any]) {
        Task {
            engine.capture(conversion: data)
            await runValidation()
        }
    }
    
    func handleLinkData(_ data: [String: Any]) {
        Task {
            engine.capture(link: data)
        }
    }
    
    func authorize() {
        Task {
            _ = await engine.authorize()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func skip() {
        Task {
            engine.skip()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkChanged(_ connected: Bool) {
        Task {
            showOfflineView = !connected
        }
    }
    
    func timeout() {
        Task {
            if !validated {
                timeoutJob?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func runValidation() async {
        if !validated {
            do {
                let valid = try await engine.checkValidity()
                validated = true
                if valid {
                    await runProcessing()
                } else {
                    timeoutJob?.cancel()
                    navigateToMain = true
                }
            } catch {
                timeoutJob?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private var validated = false
    
    private func runProcessing() async {
        do {
            try await engine.process()
            
            let eligible = engine.checkAuthEligibility()
            
            if eligible {
                timeoutJob?.cancel()
                showPermissionPrompt = true
            } else {
                timeoutJob?.cancel()
                navigateToWeb = true
            }
        } catch {
            print("🎯 [FocusShuffle] Processing error: \(error)")
            timeoutJob?.cancel()
            navigateToMain = true
        }
    }
    
    private func scheduleTimeout() {
        timeoutJob = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}
