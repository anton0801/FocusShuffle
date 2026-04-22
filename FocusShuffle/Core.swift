import Foundation

struct SystemConfig {
    static let appIdentifier = "6762527723"
    static let devKey = "V9YhD2F4GZrfMe66DmWQwK"
}

struct FocusShuffleContext {
    var conversionInfo: ConversionData
    var linkInfo: LinkData
    var configInfo: ConfigData
    var authInfo: AuthData
    var runtimeInfo: RuntimeData
    
    struct ConversionData {
        var metrics: [String: String]
        var isOrganic: Bool {
            metrics["af_status"] == "Organic"
        }
    }
    
    struct LinkData {
        var params: [String: String]
    }
    
    struct ConfigData {
        var destinationURL: String?
        var workingMode: String?
        var firstRun: Bool
        var frozen: Bool
    }
    
    struct AuthData {
        var authorized: Bool
        var rejected: Bool
        var askedOn: Date?
        
        var eligible: Bool {
            guard !authorized && !rejected else { return false }
            if let date = askedOn {
                return Date().timeIntervalSince(date) / 86400 >= 3
            }
            return true
        }
    }
    
    struct RuntimeData {
        var markers: [String: String]
    }
    
    static var empty: FocusShuffleContext {
        FocusShuffleContext(
            conversionInfo: ConversionData(metrics: [:]),
            linkInfo: LinkData(params: [:]),
            configInfo: ConfigData(
                destinationURL: nil,
                workingMode: nil,
                firstRun: true,
                frozen: false
            ),
            authInfo: AuthData(
                authorized: false,
                rejected: false,
                askedOn: nil
            ),
            runtimeInfo: RuntimeData(markers: [:])
        )
    }
}

protocol FocusShufflePlugin {
    var identifier: String { get }
    func activate(context: inout FocusShuffleContext) async throws
}

protocol DataStore {
    func persist(conversion: [String: String])
    func persist(link: [String: String])
    func persist(config url: String, mode: String)
    func persist(auth: FocusShuffleContext.AuthData)
    func flagAsLaunched()
    func restore() -> RestoredData
}

protocol Validator {
    func verify() async throws -> Bool
}

protocol ConversionFetcher {
    func retrieve(deviceID: String) async throws -> [String: Any]
}

protocol ConfigFetcher {
    func retrieve(conversion: [String: Any]) async throws -> String
}

protocol Authorizer {
    func request(completion: @escaping (Bool) -> Void)
    func activate()
}

struct RestoredData {
    var conversion: [String: String]
    var link: [String: String]
    var url: String?
    var mode: String?
    var launched: Bool
    var auth: AuthSnapshot
    
    struct AuthSnapshot {
        var authorized: Bool
        var rejected: Bool
        var askedOn: Date?
    }
}

enum PluginError: Error {
    case configInvalid
    case verificationFailed
    case connectionFailed
    case unavailable
    case timedOut
}

enum DisplayState {
    case idle
    case requestAuth
    case offline
    case showMain
    case showWeb
}
