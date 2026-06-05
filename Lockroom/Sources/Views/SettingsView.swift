import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DevelopmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""

    var body: some View {
        ZStack {
            LockroomBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    readinessPanel
                    processorPanel
                    shortcutPanel
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Production Setup")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(LockroomPalette.paper)
                Text("Connect the private processor and arm the Camera-close workflow.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LockroomPalette.fog)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)

            Button {
                dismiss()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LockroomPalette.paper)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)))
            .accessibilityLabel("Close settings")
        }
    }

    private var readinessPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Readiness", symbol: "checkmark.shield.fill")

                HStack(spacing: 10) {
                    SetupStatusTile(
                        title: "OpenAI",
                        value: store.isOpenAIConfigured ? "Connected" : "Needs key",
                        symbol: "sparkles",
                        color: store.isOpenAIConfigured ? LockroomPalette.cyan : LockroomPalette.gold
                    )
                    SetupStatusTile(
                        title: "Photos",
                        value: store.isPhotosReady ? "Allowed" : "Required",
                        symbol: "photo.stack.fill",
                        color: store.isPhotosReady ? LockroomPalette.cyan : LockroomPalette.gold
                    )
                    SetupStatusTile(
                        title: "Notify",
                        value: store.isNotificationsReady ? "Armed" : "Required",
                        symbol: "bell.badge.fill",
                        color: store.isNotificationsReady ? LockroomPalette.cyan : LockroomPalette.gold
                    )
                }

                Text(store.readinessMessage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LockroomPalette.paper.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { await store.prepareShortcutPermissions() }
                } label: {
                    Label("Prepare Camera-Close Workflow", systemImage: "camera.aperture")
                        .font(.system(size: 15, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(LockroomPalette.cinnabar)
            }
        }
    }

    private var processorPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Image processor", symbol: "network")

                VStack(alignment: .leading, spacing: 8) {
                    Text("OPENAI API KEY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(LockroomPalette.fog)
                        .tracking(1)
                    SecureField(store.loadAPIKeyPreview().isEmpty ? "sk-..." : store.loadAPIKeyPreview(), text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .padding(13)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.28)))
                        .foregroundStyle(LockroomPalette.paper)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.11)))
                }

                HStack(spacing: 10) {
                    Button {
                        store.saveAPIKey(apiKey)
                        apiKey = ""
                    } label: {
                        Label("Save Key", systemImage: "key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LockroomPalette.cinnabar)

                    Button {
                        store.saveAPIKey("")
                        apiKey = ""
                    } label: {
                        Label("Clear", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(LockroomPalette.paper)
                }
                .font(.system(size: 13, weight: .bold))

                Text("Keys are stored in this iPhone's Keychain for local testing.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LockroomPalette.fog)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var shortcutPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 13) {
                SectionLabel(title: "Shortcut trigger", symbol: "square.stack.3d.up.fill")
                Text("Automation: Camera is Closed -> Run Shortcut -> Lockroom: Develop Latest Photo.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LockroomPalette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The app reads the newest image from Photos, sends it to GPT Image 2, then returns a rich notification with the finished frame.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LockroomPalette.fog)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SetupStatusTile: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(LockroomPalette.fog)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(LockroomPalette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.19))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.30)))
        )
    }
}
