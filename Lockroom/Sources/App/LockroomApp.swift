import SwiftUI
import UserNotifications

@main
struct LockroomApp: App {
    @StateObject private var store = DevelopmentStore.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationCoordinator.shared
    }

    var body: some Scene {
        WindowGroup {
            LockroomRootView()
                .environmentObject(store)
                .task {
                    await store.refreshSystemReadiness()
                }
        }
    }
}
