import AppsFlyerLib
import Foundation

final class AttributionPlugin: ConversionFetcher {
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.client = URLSession(configuration: config)
    }
    
    func retrieve(deviceID: String) async throws -> [String: Any] {
        var builder = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(SystemConfig.appIdentifier)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: SystemConfig.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let requestURL = builder?.url else {
            throw PluginError.configInvalid
        }
        
        var req = URLRequest(url: requestURL)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, resp) = try await client.data(for: req)
        
        guard let httpResp = resp as? HTTPURLResponse,
              (200...299).contains(httpResp.statusCode) else {
            throw PluginError.connectionFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PluginError.configInvalid
        }
        
        return json
    }
}
