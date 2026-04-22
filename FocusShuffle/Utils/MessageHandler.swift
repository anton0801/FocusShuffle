import Foundation

final class MessageHandler: NSObject {
    func handle(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: "temp_url")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        
        return nil
    }
}
