import Foundation
import AppsFlyerLib

final class FocusShuffleEngine {
    
    private let store: DataStore
    private let validator: Validator
    private let conversionFetcher: ConversionFetcher
    private let configFetcher: ConfigFetcher
    private let authorizer: Authorizer
    
    private var context: FocusShuffleContext = .empty
    
    init(
        store: DataStore,
        validator: Validator,
        conversionFetcher: ConversionFetcher,
        configFetcher: ConfigFetcher,
        authorizer: Authorizer
    ) {
        self.store = store
        self.validator = validator
        self.conversionFetcher = conversionFetcher
        self.configFetcher = configFetcher
        self.authorizer = authorizer
    }
    
    // MARK: - Operations
    
    func startup() async {
        let restored = store.restore()
        
        context.conversionInfo.metrics = restored.conversion
        context.linkInfo.params = restored.link
        context.configInfo.destinationURL = restored.url
        context.configInfo.workingMode = restored.mode
        context.configInfo.firstRun = !restored.launched
        context.authInfo.authorized = restored.auth.authorized
        context.authInfo.rejected = restored.auth.rejected
        context.authInfo.askedOn = restored.auth.askedOn
    }
    
    func capture(conversion: [String: Any]) {
        let strings = conversion.mapValues { "\($0)" }
        context.conversionInfo.metrics = strings
        store.persist(conversion: strings)
    }
    
    func capture(link: [String: Any]) {
        let strings = link.mapValues { "\($0)" }
        context.linkInfo.params = strings
        store.persist(link: strings)
    }
    
    func checkValidity() async throws -> Bool {
        guard !context.conversionInfo.metrics.isEmpty else {
            return false
        }
        
        do {
            let valid = try await validator.verify()
            return valid
        } catch {
            print("🎯 [FocusShuffle] Validity check failed: \(error)")
            throw error
        }
    }
    
    func process() async throws {
        guard !context.configInfo.frozen,
              !context.conversionInfo.metrics.isEmpty else {
            throw PluginError.configInvalid
        }
        
        // Handle temp override
        if let temp = UserDefaults.standard.string(forKey: "temp_url"),
           !temp.isEmpty {
            let needsAuth = context.authInfo.eligible
            seal(url: temp, mode: "Active")
            return
        }
        
        let organicMarked = context.runtimeInfo.markers["organic_done"] == "true"
        if context.conversionInfo.isOrganic &&
           context.configInfo.firstRun &&
           !organicMarked {
            
            context.runtimeInfo.markers["organic_done"] = "true"
            try await processOrganic()
        }
        
        let convDict = context.conversionInfo.metrics.mapValues { $0 as Any }
        let url = try await configFetcher.retrieve(conversion: convDict)
        
        let needsAuth = context.authInfo.eligible
        
        seal(url: url, mode: "Active")
    }
    
    func authorize() async -> FocusShuffleContext.AuthData {
        var local = context.authInfo
        
        let updated = await withCheckedContinuation { continuation in
            authorizer.request { granted in
                var auth = local
                
                if granted {
                    auth.authorized = true
                    auth.rejected = false
                    auth.askedOn = Date()
                    self.authorizer.activate()
                } else {
                    auth.authorized = false
                    auth.rejected = true
                    auth.askedOn = Date()
                }
                
                continuation.resume(returning: auth)
            }
        }
        
        context.authInfo = updated
        store.persist(auth: updated)
        
        return updated
    }
    
    func skip() {
        context.authInfo.askedOn = Date()
        store.persist(auth: context.authInfo)
    }
    
    func checkAuthEligibility() -> Bool {
        return context.authInfo.eligible
    }
    
    func snapshot() -> FocusShuffleContext {
        return context
    }
    
    private func processOrganic() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !context.configInfo.frozen else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        var fetched = try await conversionFetcher.retrieve(deviceID: deviceID)
        
        for (k, v) in context.linkInfo.params {
            if fetched[k] == nil {
                fetched[k] = v
            }
        }
        
        let strings = fetched.mapValues { "\($0)" }
        context.conversionInfo.metrics = strings
        store.persist(conversion: strings)
    }
    
    private func seal(url: String, mode: String) {
        context.configInfo.destinationURL = url
        context.configInfo.workingMode = mode
        context.configInfo.firstRun = false
        context.configInfo.frozen = true
        
        store.persist(config: url, mode: mode)
        store.flagAsLaunched()
    }
}
