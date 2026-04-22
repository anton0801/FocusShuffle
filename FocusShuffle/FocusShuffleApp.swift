import SwiftUI

@main
struct FocusShuffleApp: App {
    
    @UIApplicationDelegateAdaptor(Lifecycle.self) var lifecycle

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
    
}
