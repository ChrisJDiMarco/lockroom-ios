import PhotosUI
import SwiftUI
import UIKit

struct LockroomRootView: View {
    @EnvironmentObject private var store: DevelopmentStore
    @State private var pickerItem: PhotosPickerItem?
    @State private var stagedPhoto: StagedPhoto?
    @State private var showsSettings = false
    @State private var showsDetail = false
    @State private var fullscreenImage: InspectableFrameImage?

    var body: some View {
        NavigationStack {
            ZStack {
                LockroomBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        readinessStrip
                        frameStage
                        captureConsole
                        shortcutFlow
                        historyStack
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showsDetail) {
                if let frame = store.selectedFrame {
                    FrameDetailView(frame: frame)
                        .environmentObject(store)
                }
            }
            .fullScreenCover(item: $fullscreenImage) { item in
                FullscreenImageView(item: item) {
                    if item.canSave, let frame = store.selectedFrame {
                        Task { await store.saveFrameToPhotos(frame) }
                    }
                }
            }
            .onChange(of: pickerItem) { _, newValue in
                Task { await loadPickedImage(newValue) }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LOCKROOM")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(LockroomPalette.paper)
                    .tracking(1)
                Text("Shoot naturally. Close Camera. Receive the developed frame.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LockroomPalette.fog)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button {
                showsSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LockroomPalette.paper)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LockroomPalette.paper.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.14)))
            )
            .accessibilityLabel("Open Lockroom settings")
        }
        .padding(.top, 18)
    }

    private var readinessStrip: some View {
        HStack(spacing: 8) {
            ReadinessSignal(
                title: "GPT Image 2",
                detail: store.isOpenAIConfigured ? "Armed" : "Needs key",
                symbol: "sparkles",
                color: store.isOpenAIConfigured ? LockroomPalette.cyan : LockroomPalette.gold
            )
            ReadinessSignal(
                title: "Photos",
                detail: store.isPhotosReady ? "Allowed" : "Setup",
                symbol: "photo.stack.fill",
                color: store.isPhotosReady ? LockroomPalette.cyan : LockroomPalette.gold
            )
            ReadinessSignal(
                title: "Notify",
                detail: store.isNotificationsReady ? "Armed" : "Setup",
                symbol: "bell.badge.fill",
                color: store.isNotificationsReady ? LockroomPalette.cyan : LockroomPalette.gold
            )
        }
    }

    @ViewBuilder
    private var frameStage: some View {
        if let stagedPhoto {
            SelectedPhotoStage(
                photo: stagedPhoto,
                onDevelop: developStagedPhoto,
                onInspect: {
                    fullscreenImage = .selectedPhoto(image: stagedPhoto.image)
                },
                onClear: {
                    self.stagedPhoto = nil
                    store.noteSelectedPhotoCleared()
                }
            )
        } else if let frame = store.selectedFrame {
            DevelopedFrameHero(
                frame: frame,
                onOpenDetail: {
                    showsDetail = true
                },
                onInspectImage: { item in
                    fullscreenImage = item
                }
            )
        } else {
            EmptyFrameStage()
        }
    }

    private var captureConsole: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Capture console", symbol: "camera.aperture")

                Button {
                    if stagedPhoto != nil {
                        developStagedPhoto()
                    } else {
                        guard store.isOpenAIConfigured else {
                            store.noteSetupRequiredForLatestPhoto()
                            showsSettings = true
                            return
                        }

                        Task { await store.developLatestPhotoManually() }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: stagedPhoto == nil ? "camera.fill" : "wand.and.rays")
                            .font(.system(size: 18, weight: .bold))
                        Text(stagedPhoto == nil ? "Develop Latest Photo" : "Develop Selected Photo")
                            .font(.system(size: 17, weight: .black))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LockroomPalette.cinnabar)
                            .shadow(color: LockroomPalette.cinnabar.opacity(0.34), radius: 18, x: 0, y: 10)
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    if store.isOpenAIConfigured {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            SecondaryActionLabel(
                                title: stagedPhoto == nil ? "Choose Photo" : "Change Photo",
                                symbol: "photo.on.rectangle.angled"
                            )
                        }
                    } else {
                        Button {
                            store.noteSetupRequiredForImport()
                            showsSettings = true
                        } label: {
                            SecondaryActionLabel(title: "Choose Photo", symbol: "photo.on.rectangle.angled")
                        }
                        .buttonStyle(.plain)
                    }

                    if stagedPhoto == nil {
                        Button {
                            showsSettings = true
                        } label: {
                            SecondaryActionLabel(title: "Setup", symbol: "key.fill")
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            stagedPhoto = nil
                            store.noteSelectedPhotoCleared()
                        } label: {
                            SecondaryActionLabel(title: "Clear", symbol: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(store.readinessMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LockroomPalette.fog)
                    .fixedSize(horizontal: false, vertical: true)

                LiveStatusLine(message: store.latestMessage)
            }
        }
    }

    private var shortcutFlow: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Lock-screen loop", symbol: "rectangle.portrait.and.arrow.right")

                HStack(spacing: 9) {
                    FlowNode(symbol: "camera.fill", title: "Shoot", detail: "Native Camera")
                    FlowNode(symbol: "lock.fill", title: "Close", detail: "Shortcut fires")
                    FlowNode(symbol: "wand.and.rays", title: "Develop", detail: "GPT Image 2")
                    FlowNode(symbol: "bell.fill", title: "Return", detail: "Tap result")
                }
            }
        }
    }

    @ViewBuilder
    private var historyStack: some View {
        if store.frames.isEmpty == false {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(title: "Recent frames", symbol: "tray.full.fill")

                VStack(spacing: 10) {
                    ForEach(store.frames.prefix(6)) { frame in
                        FrameRow(
                            frame: frame,
                            onOpenDetail: {
                                store.selectedFrameID = frame.id
                                showsDetail = true
                            },
                            onInspectImage: { item in
                                store.selectedFrameID = frame.id
                                fullscreenImage = item
                            }
                        )
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LockroomPalette.paper.opacity(0.055))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
                        )
                    }
                }
            }
        }
    }

    private func loadPickedImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        defer { pickerItem = nil }

        guard store.isOpenAIConfigured else {
            store.noteSetupRequiredForImport()
            showsSettings = true
            return
        }

        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                store.noteImportFailed()
                return
            }

            stagedPhoto = StagedPhoto(image: image)
            store.noteSelectedPhotoReady()
        } catch {
            store.noteImportFailed()
        }
    }

    private func developStagedPhoto() {
        guard store.isOpenAIConfigured else {
            store.noteSetupRequiredForImport()
            showsSettings = true
            return
        }

        guard let stagedPhoto else {
            store.noteNoSelectedPhoto()
            return
        }

        self.stagedPhoto = nil
        Task {
            await store.develop(image: stagedPhoto.image, source: stagedPhoto.source)
        }
    }
}

private struct StagedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let selectedAt = Date()
    let source = "Chosen photo"
}

private struct ReadinessSignal: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(LockroomPalette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(detail)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.20))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.28)))
        )
    }
}

private struct SecondaryActionLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.system(size: 14, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .foregroundStyle(LockroomPalette.paper)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LockroomPalette.paper.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12)))
        )
    }
}

private struct LiveStatusLine: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(LockroomPalette.cyan)
            Text(message)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(LockroomPalette.paper.opacity(0.78))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.20))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.09)))
        )
    }
}

private struct FlowNode: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(LockroomPalette.cyan)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(LockroomPalette.cyan.opacity(0.12))
                )
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(LockroomPalette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(LockroomPalette.fog)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.16))
        )
    }
}

private struct SelectedPhotoStage: View {
    let photo: StagedPhoto
    let onDevelop: () -> Void
    let onInspect: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Selected photo", symbol: "viewfinder")

            ZStack(alignment: .bottomLeading) {
                Button {
                    onInspect()
                } label: {
                    Image(uiImage: photo.image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 410)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.16), lineWidth: 1))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(LockroomPalette.paper)
                                .padding(10)
                                .background(.black.opacity(0.46), in: Circle())
                                .padding(12)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open selected photo full screen")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        SmallStatusPill(text: "Ready", symbol: "checkmark.seal.fill", color: LockroomPalette.cyan)
                        Text(photo.selectedAt, style: .relative)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(LockroomPalette.fog)
                    }

                    Text("Ready to develop")
                        .font(.system(size: 31, weight: .black, design: .serif))
                        .foregroundStyle(LockroomPalette.paper)
                        .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)

                    Text("Review the selected photo, then run the GPT Image 2 development pass when you are ready.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LockroomPalette.paper.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 9) {
                        Button {
                            onDevelop()
                        } label: {
                            Label("Develop Selected Photo", systemImage: "wand.and.rays")
                                .font(.system(size: 13, weight: .black))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LockroomPalette.cinnabar)

                        Button {
                            onClear()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .black))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.bordered)
                        .tint(LockroomPalette.paper)
                        .accessibilityLabel("Clear selected photo")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.88), .black.opacity(0.58), .black.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
    }
}

private struct EmptyFrameStage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Current frame", symbol: "viewfinder")

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.38),
                                LockroomPalette.paper.opacity(0.07),
                                LockroomPalette.gold.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.13)))

                VStack(spacing: 18) {
                    ApertureMark()
                        .frame(width: 170, height: 170)
                    VStack(spacing: 8) {
                        Text("Waiting for the first frame")
                            .font(.system(size: 25, weight: .black, design: .serif))
                            .foregroundStyle(LockroomPalette.paper)
                        Text("Take a photo, close Camera, or develop the latest capture now.")
                            .font(.system(size: 13, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(LockroomPalette.fog)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .frame(height: 365)
        }
    }
}

private struct ApertureMark: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(LockroomPalette.paper.opacity(0.12), lineWidth: 28)
            Circle()
                .stroke(LockroomPalette.cinnabar.opacity(0.72), lineWidth: 2)
                .padding(16)
            Circle()
                .stroke(LockroomPalette.gold.opacity(0.92), lineWidth: 2)
                .padding(27)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, LockroomPalette.gold, LockroomPalette.paper, LockroomPalette.gold, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .shadow(color: LockroomPalette.gold.opacity(0.9), radius: 12)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LockroomPalette.cyan.opacity(0.20), Color.black.opacity(0.55)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .padding(48)
        }
    }
}
