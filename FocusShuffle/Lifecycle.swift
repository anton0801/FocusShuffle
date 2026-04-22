import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class Lifecycle: UIResponder, UIApplicationDelegate {
    
    private var tracker: ConversionTracker?
    private var messenger: MessageHandler?
    private var analytics: AnalyticsEngine?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let track = ConversionTracker()
        self.tracker = track
        
        let msg = MessageHandler()
        self.messenger = msg
        
        let engine = AnalyticsEngine(tracker: track)
        self.analytics = engine
        
        track.onConversionReady = { [weak self] data in
            self?.relayConversion(data)
        }
        
        track.onLinkReady = { [weak self] data in
            self?.relayLink(data)
        }
        
        initializeFirebase()
        initializeMessaging()
        engine.setup()
        
        if let msgData = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            msg.handle(msgData)
        }
        
        watchLifecycle()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func initializeFirebase() {
        FirebaseApp.configure()
    }
    
    private func initializeMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func watchLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func onActivation() {
        analytics?.begin()
    }
    
    private func relayConversion(_ data: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("ConversionDataReceived"),
                object: nil,
                userInfo: ["conversionData": data]
            )
        }
    }
    
    private func relayLink(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

// MARK: - Messaging Delegate

extension Lifecycle: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: "fcm_token")
            UserDefaults.standard.set(t, forKey: "push_token")
            UserDefaults(suiteName: "group.focusshuffle.core")?.set(t, forKey: "shared_fcm")
        }
    }
}

extension Lifecycle: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        messenger?.handle(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        messenger?.handle(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        messenger?.handle(userInfo)
        completionHandler(.newData)
    }
}

final class AnalyticsEngine: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private weak var tracker: ConversionTracker?
    
    init(tracker: ConversionTracker) {
        self.tracker = tracker
    }
    
    func setup() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = SystemConfig.devKey
        sdk.appleAppID = SystemConfig.appIdentifier
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func begin() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    // MARK: - AppsFlyer Delegate
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        tracker?.receiveConversion(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        let errorData: [AnyHashable: Any] = [
            "error": true,
            "error_desc": error.localizedDescription
        ]
        tracker?.receiveConversion(errorData)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        tracker?.receiveLink(link.clickEvent)
    }
}
