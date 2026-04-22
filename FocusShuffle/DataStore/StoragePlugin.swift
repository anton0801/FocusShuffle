import Foundation

final class StoragePlugin: DataStore {
    private let container: UserDefaults
    private let fallback: UserDefaults
    
    init() {
        self.container = UserDefaults(suiteName: "group.focusshuffle.core")!
        self.fallback = UserDefaults.standard
    }
    
    private struct StorageKeys {
        static let conv = "fs_conv"
        static let link = "fs_link"
        static let dest = "fs_dest"
        static let mode = "fs_mode"
        static let boot = "fs_boot"
        static let authOk = "fs_auth_yes"
        static let authNo = "fs_auth_no"
        static let authTs = "fs_auth_ts"
    }
    
    func persist(conversion: [String: String]) {
        if let packed = pack(conversion) {
            container.set(packed, forKey: StorageKeys.conv)
        }
    }
    
    func persist(link: [String: String]) {
        if let packed = pack(link) {
            let encoded = customEncode(packed)
            container.set(encoded, forKey: StorageKeys.link)
        }
    }
    
    func persist(config url: String, mode: String) {
        container.set(url, forKey: StorageKeys.dest)
        fallback.set(url, forKey: StorageKeys.dest)
        container.set(mode, forKey: StorageKeys.mode)
    }
    
    func persist(auth: FocusShuffleContext.AuthData) {
        container.set(auth.authorized, forKey: StorageKeys.authOk)
        container.set(auth.rejected, forKey: StorageKeys.authNo)
        if let date = auth.askedOn {
            let ms = date.timeIntervalSince1970 * 1000
            container.set(ms, forKey: StorageKeys.authTs)
        }
    }
    
    func flagAsLaunched() {
        container.set(true, forKey: StorageKeys.boot)
    }
    
    func restore() -> RestoredData {
        let convPacked = container.string(forKey: StorageKeys.conv) ?? ""
        let conversion = unpack(convPacked) ?? [:]
        
        let linkEncoded = container.string(forKey: StorageKeys.link) ?? ""
        let linkPacked = customDecode(linkEncoded) ?? ""
        let link = unpack(linkPacked) ?? [:]
        
        let url = container.string(forKey: StorageKeys.dest)
        let mode = container.string(forKey: StorageKeys.mode)
        let launched = container.bool(forKey: StorageKeys.boot)
        
        let authOk = container.bool(forKey: StorageKeys.authOk)
        let authNo = container.bool(forKey: StorageKeys.authNo)
        let authMs = container.double(forKey: StorageKeys.authTs)
        let authDate = authMs > 0 ? Date(timeIntervalSince1970: authMs / 1000) : nil
        
        return RestoredData(
            conversion: conversion,
            link: link,
            url: url,
            mode: mode,
            launched: launched,
            auth: RestoredData.AuthSnapshot(
                authorized: authOk,
                rejected: authNo,
                askedOn: authDate
            )
        )
    }
    
    private func pack(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func unpack(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let anyDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return anyDict.mapValues { "\($0)" }
    }
    
    private func customEncode(_ input: String) -> String {
        let base64 = Data(input.utf8).base64EncodedString()
        return base64
            .replacingOccurrences(of: "=", with: "/")
            .replacingOccurrences(of: "+", with: "\\")
    }
    
    private func customDecode(_ encoded: String) -> String? {
        let base64 = encoded
            .replacingOccurrences(of: "/", with: "=")
            .replacingOccurrences(of: "\\", with: "+")
        guard let data = Data(base64Encoded: base64),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        return decoded
    }
}
