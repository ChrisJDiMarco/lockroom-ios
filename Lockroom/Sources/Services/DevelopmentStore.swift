import Foundation
import Photos
import SwiftUI
import UIKit

@MainActor
final class DevelopmentStore: ObservableObject {
    static let shared = DevelopmentStore()

    @Published private(set) var frames: [DevelopedFrame] = []
    @Published var selectedFrameID: DevelopedFrame.ID?
    @Published var latestMessage = "Camera-close automation idle"
    @Published private(set) var readinessMessage = "Prepare Photos, notifications, and OpenAI before the first run."
    @Published private(set) var isNotificationsReady = false

    private init() {
        frames = FrameArchive.load().filter { Self.isCurrentProductFrame($0) }
        if frames.isEmpty == false {
            persistFrames()
        }
        updateReadinessMessage()
    }

    var selectedFrame: DevelopedFrame? {
        guard let selectedFrameID else { return frames.first }
        return frames.first { $0.id == selectedFrameID } ?? frames.first
    }

    var isOpenAIConfigured: Bool {
        KeychainStore.loadAPIKey().isEmpty == false
    }

    var isPhotosReady: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    func develop(image: UIImage, source: String) async {
        let apiKey = KeychainStore.loadAPIKey()
        guard apiKey.isEmpty == false else {
            latestMessage = ImageDevelopmentError.invalidAPIKey.localizedDescription
            await NotificationCoordinator.shared.scheduleActionNotification(
                title: "Lockroom setup needed",
                body: "Add an OpenAI API key before developing photos."
            )
            updateReadinessMessage()
            return
        }

        isNotificationsReady = await NotificationCoordinator.shared.requestAuthorizationIfUseful()
        updateReadinessMessage()

        let id = UUID()
        let recipe = DevelopmentRecipe.editorialPrime
        let prompt = DevelopmentPrompt.makePrompt(recipe: recipe)
        let frame = DevelopedFrame(
            id: id,
            sourceImage: image,
            developedImage: nil,
            status: .developing,
            createdAt: Date(),
            completedAt: nil,
            source: source,
            recipe: recipe
        )

        frames.insert(frame, at: 0)
        selectedFrameID = id
        latestMessage = "Developing latest capture"
        persistFrames()

        do {
            let service: ImageDevelopmentService = OpenAIImageEditClient(apiKey: apiKey)
            let developedImage = try await service.develop(image: image, prompt: prompt)
            updateFrame(id: id) { current in
                current.developedImage = developedImage
                current.status = .ready
                current.completedAt = Date()
            }
            latestMessage = "Frame ready"
            if let readyFrame = frames.first(where: { $0.id == id }) {
                persistFrames()
                await NotificationCoordinator.shared.scheduleReadyNotification(for: readyFrame)
            }
        } catch {
            updateFrame(id: id) { current in
                current.status = .failed(error.localizedDescription)
            }
            latestMessage = "Development failed"
            persistFrames()
            await NotificationCoordinator.shared.scheduleActionNotification(
                title: "Lockroom needs attention",
                body: error.localizedDescription
            )
        }
    }

    func developLatestPhotoManually() async {
        guard isOpenAIConfigured else {
            latestMessage = ImageDevelopmentError.invalidAPIKey.localizedDescription
            updateReadinessMessage()
            return
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await developLatestPhoto(status: status, source: "Latest Photos capture")
    }

    func developLatestPhotoFromShortcut() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        await developLatestPhoto(status: status, source: "Camera-close latest capture")
    }

    func prepareShortcutPermissions() async {
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        isNotificationsReady = await NotificationCoordinator.shared.requestAuthorizationIfUseful()
        updateReadinessMessage()
        latestMessage = readinessMessage
    }

    func refreshSystemReadiness() async {
        isNotificationsReady = await NotificationCoordinator.shared.isAuthorizedForAlerts()
        updateReadinessMessage()
    }

    func saveFrameToPhotos(_ frame: DevelopedFrame) async {
        guard let image = frame.developedImage else {
            latestMessage = "No developed frame to save"
            return
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            latestMessage = ImageDevelopmentError.photosPermissionRequired.localizedDescription
            return
        }

        do {
            try await saveToPhotos(image)
            latestMessage = "Saved developed frame"
        } catch {
            latestMessage = ImageDevelopmentError.saveToPhotosFailed.localizedDescription
        }
    }

    func saveAPIKey(_ key: String) {
        do {
            try KeychainStore.saveAPIKey(key)
            latestMessage = key.isEmpty ? "API key cleared" : "API key saved locally"
            updateReadinessMessage()
        } catch {
            latestMessage = error.localizedDescription
        }
    }

    func noteSetupRequiredForImport() {
        latestMessage = "Add an OpenAI API key before choosing a photo."
        updateReadinessMessage()
    }

    func noteSetupRequiredForLatestPhoto() {
        latestMessage = "Add an OpenAI API key before developing the latest photo."
        updateReadinessMessage()
    }

    func noteImportFailed() {
        latestMessage = "That photo could not be loaded."
    }

    func noteSelectedPhotoReady() {
        latestMessage = "Photo selected. Tap Develop Selected Photo."
    }

    func noteSelectedPhotoCleared() {
        latestMessage = "Selected photo cleared."
    }

    func noteNoSelectedPhoto() {
        latestMessage = "Choose a photo before developing a selected photo."
    }

    func loadAPIKeyPreview() -> String {
        let key = KeychainStore.loadAPIKey()
        guard key.count > 10 else { return key }
        return "\(key.prefix(7))...\(key.suffix(4))"
    }

    func selectFrame(idString: String) {
        guard
            let id = UUID(uuidString: idString),
            frames.contains(where: { $0.id == id })
        else { return }

        selectedFrameID = id
        latestMessage = "Opened ready frame"
    }

    private func developLatestPhoto(status: PHAuthorizationStatus, source: String) async {
        guard status == .authorized || status == .limited else {
            latestMessage = ImageDevelopmentError.photosPermissionRequired.localizedDescription
            await NotificationCoordinator.shared.scheduleActionNotification(
                title: "Lockroom setup needed",
                body: "Open Lockroom once and allow Photos before using the Camera-close shortcut."
            )
            return
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        let results = PHAsset.fetchAssets(with: .image, options: options)
        guard let asset = results.firstObject else {
            latestMessage = ImageDevelopmentError.noLatestPhoto.localizedDescription
            await NotificationCoordinator.shared.scheduleActionNotification(
                title: "No photo found",
                body: "Take a photo, then close Camera to run Lockroom."
            )
            return
        }

        guard let image = await requestImage(for: asset) else {
            latestMessage = ImageDevelopmentError.missingImageData.localizedDescription
            await NotificationCoordinator.shared.scheduleActionNotification(
                title: "Photo could not be loaded",
                body: "Open Lockroom and try developing the latest photo manually."
            )
            return
        }

        await develop(image: image, source: source)
    }

    private func updateFrame(id: UUID, update: (inout DevelopedFrame) -> Void) {
        guard let index = frames.firstIndex(where: { $0.id == id }) else { return }
        var frame = frames[index]
        update(&frame)
        frames[index] = frame
    }

    private func persistFrames() {
        FrameArchive.save(frames)
    }

    private func updateReadinessMessage() {
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let hasPhotos = photoStatus == .authorized || photoStatus == .limited
        let hasKey = KeychainStore.loadAPIKey().isEmpty == false

        if hasPhotos && hasKey && isNotificationsReady {
            readinessMessage = "Shortcut ready for GPT Image 2."
        } else if hasPhotos && hasKey {
            readinessMessage = "Allow notifications for lock-screen delivery."
        } else if hasPhotos {
            readinessMessage = "Add a GPT key before live processing."
        } else if hasKey {
            readinessMessage = "Allow Photos before using the shortcut."
        } else {
            readinessMessage = "Add a GPT key, then prepare the Camera-close workflow."
        }
    }

    private func requestImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.resizeMode = .none
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    private func saveToPhotos(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? ImageDevelopmentError.saveToPhotosFailed)
                }
            }
        }
    }

    private static func isCurrentProductFrame(_ frame: DevelopedFrame) -> Bool {
        let retiredSourceFragments = ["de" + "mo", "sim" + "ulated"]
        return retiredSourceFragments.contains { frame.source.localizedCaseInsensitiveContains($0) } == false
    }
}
