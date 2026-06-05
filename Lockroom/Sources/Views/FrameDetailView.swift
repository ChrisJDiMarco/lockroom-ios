import SwiftUI

struct FrameDetailView: View {
    let frame: DevelopedFrame
    @EnvironmentObject private var store: DevelopmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var fullscreenImage: InspectableFrameImage?

    var body: some View {
        ZStack {
            LockroomBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    mainImage
                    actionRow
                    BeforeAfterStrip(frame: frame) { item in
                        fullscreenImage = item
                    }
                    failurePanel
                    developmentPanel
                }
                .padding(18)
            }
        }
        .fullScreenCover(item: $fullscreenImage) { item in
            FullscreenImageView(item: item) {
                if item.canSave {
                    Task { await store.saveFrameToPhotos(frame) }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Finished Frame")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(LockroomPalette.paper)
                Text(frame.completedAt ?? frame.createdAt, style: .time)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(LockroomPalette.fog)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LockroomPalette.paper)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)))
            .accessibilityLabel("Close frame detail")
        }
    }

    private var mainImage: some View {
        Image(uiImage: frame.developedImage ?? frame.sourceImage)
            .resizable()
            .scaledToFill()
            .frame(height: 470)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.15), lineWidth: 1))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(frame.recipe.name)
                        .font(.system(size: 27, weight: .black, design: .serif))
                        .foregroundStyle(LockroomPalette.paper)
                    Text(frame.source)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(LockroomPalette.fog)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.78), .black.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(LockroomPalette.paper)
                    .padding(10)
                    .background(.black.opacity(0.46), in: Circle())
                    .padding(12)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                fullscreenImage = frame.inspectableCurrentImage()
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens the frame full screen")
    }

    @ViewBuilder
    private var actionRow: some View {
        if frame.developedImage != nil {
            Button {
                Task { await store.saveFrameToPhotos(frame) }
            } label: {
                Label("Save Developed Frame", systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 15, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(LockroomPalette.cinnabar)
        }
    }

    @ViewBuilder
    private var failurePanel: some View {
        if case .failed(let message) = frame.status {
            GlassPanel {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(title: "Attention needed", symbol: "exclamationmark.triangle.fill")
                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LockroomPalette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var developmentPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Development recipe", symbol: "dial.high.fill")
                NoteLine(title: "Lens", value: frame.recipe.lensRead)
                NoteLine(title: "Tone", value: frame.recipe.toneRead)
                NoteLine(title: "Intent", value: frame.recipe.outputIntent)
            }
        }
    }
}

struct NoteLine: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(LockroomPalette.cyan)
                .tracking(1)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LockroomPalette.paper.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
