import Foundation
import UIKit
import UserNotifications

final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCoordinator()

    private override init() {}

    func requestAuthorizationIfUseful() async -> Bool {
        let existingStatus = await authorizationStatus()
        guard existingStatus == .notDetermined else {
            return Self.canPostNotifications(status: existingStatus)
        }

        do {
            let isAuthorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return isAuthorized
        } catch {
            // Notification permission failures should not block photo development.
            return false
        }
    }

    func isAuthorizedForAlerts() async -> Bool {
        let status = await authorizationStatus()
        return Self.canPostNotifications(status: status)
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let frameID = response.notification.request.content.userInfo["frameID"] as? String else {
            return
        }

        await DevelopmentStore.shared.selectFrame(idString: frameID)
    }

    func scheduleReadyNotification(for frame: DevelopedFrame) async {
        let content = UNMutableNotificationContent()
        content.title = "Lockroom frame ready"
        content.body = "Your photo finished developing."
        content.sound = .default
        content.userInfo = ["frameID": frame.id.uuidString]

        let image = frame.developedImage ?? frame.sourceImage
        if let attachment = try? makeAttachment(from: image, id: frame.id) {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(
            identifier: "lockroom-\(frame.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func scheduleActionNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "lockroom-action-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func makeAttachment(from image: UIImage, id: UUID) throws -> UNNotificationAttachment {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LockroomNotifications", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw ImageDevelopmentError.missingImageData
        }
        try data.write(to: url, options: [.atomic])
        return try UNNotificationAttachment(identifier: id.uuidString, url: url)
    }

    private static func canPostNotifications(status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }
}
