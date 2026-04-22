import Foundation
import AppsFlyerLib
import FirebaseCore
import WebKit
import FirebaseMessaging

final class RemoteConfigPlugin: ConfigFetcher {
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.client = URLSession(configuration: config)
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func retrieve(conversion: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: "https://focusshuffle.com/config.php") else {
            throw PluginError.configInvalid
        }
        
        var payload: [String: Any] = conversion
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(SystemConfig.appIdentifier)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastErr: Error?
        let delays: [Double] = [38.0, 76.0, 152.0]
        
        for (idx, delay) in delays.enumerated() {
            do {
                let (data, resp) = try await client.data(for: req)
                
                guard let httpResp = resp as? HTTPURLResponse else {
                    throw PluginError.connectionFailed
                }
                
                if httpResp.statusCode == 404 {
                    throw PluginError.unavailable
                }
                
                if (200...299).contains(httpResp.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw PluginError.configInvalid
                    }
                    
                    guard let ok = json["ok"] as? Bool else {
                        throw PluginError.configInvalid
                    }
                    
                    if !ok {
                        throw PluginError.unavailable
                    }
                    
                    guard let url = json["url"] as? String else {
                        throw PluginError.configInvalid
                    }
                    
                    return url
                    
                } else if httpResp.statusCode == 429 {
                    let backoff = delay * Double(idx + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw PluginError.connectionFailed
                }
            } catch {
                if case PluginError.unavailable = error {
                    throw error
                }
                
                lastErr = error
                if idx < delays.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastErr ?? PluginError.connectionFailed
    }
}
