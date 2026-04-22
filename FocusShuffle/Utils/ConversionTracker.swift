import Foundation

final class ConversionTracker: NSObject {
    var onConversionReady: (([AnyHashable: Any]) -> Void)?
    var onLinkReady: (([AnyHashable: Any]) -> Void)?
    
    private var convBuffer: [AnyHashable: Any] = [:]
    private var linkBuffer: [AnyHashable: Any] = [:]
    private var combineTimer: Timer?
    
    func receiveConversion(_ data: [AnyHashable: Any]) {
        convBuffer = data
        scheduleCombine()
        
        if !linkBuffer.isEmpty {
            combine()
        }
    }
    
    func receiveLink(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "fs_boot") else { return }
        
        linkBuffer = data
        onLinkReady?(data)
        combineTimer?.invalidate()
        
        if !convBuffer.isEmpty {
            combine()
        }
    }
    
    private func scheduleCombine() {
        combineTimer?.invalidate()
        combineTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.combine()
        }
    }
    
    private func combine() {
        var result = convBuffer
        
        for (k, v) in linkBuffer {
            let key = "deep_\(k)"
            if result[key] == nil {
                result[key] = v
            }
        }
        
        onConversionReady?(result)
    }
}
