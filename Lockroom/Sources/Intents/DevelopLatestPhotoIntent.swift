import AppIntents

struct DevelopLatestPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Develop Latest Photo"
    static var description = IntentDescription("Processes the newest image in Photos through Lockroom.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        await DevelopmentStore.shared.developLatestPhotoFromShortcut()
        return .result(dialog: "Lockroom is developing your latest photo.")
    }
}

struct LockroomShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DevelopLatestPhotoIntent(),
            phrases: [
                "Develop latest photo in \(.applicationName)",
                "Run darkroom in \(.applicationName)"
            ],
            shortTitle: "Develop Photo",
            systemImageName: "camera.aperture"
        )
    }
}

