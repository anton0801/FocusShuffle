import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UserNotifications
import Supabase


final class AuthorizationPlugin: Authorizer {
    func request(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func activate() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

