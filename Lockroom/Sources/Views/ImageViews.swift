import SwiftUI
import UIKit

struct DevelopedFrameHero: View {
    let frame: DevelopedFrame
    let onOpenDetail: () -> Void
    let onInspectImage: (InspectableFrameImage) -> Void
    @State private var revealDeveloped = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Current frame", symbol: "viewfinder")

            ZStack(alignment: .bottomLeading) {
                Image(uiImage: displayedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 410)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        StatusChip(status: frame.status)
                            .padding(12)
                    }
                    .overlay(alignment: .topLeading) {
                        SourceChip(text: frame.source)
                            .padding(12)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        onInspectImage(frame.inspectableCurrentImage(showDeveloped: revealDeveloped))
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Opens the frame full screen")

                VStack(alignment: .leading, spacing: 10) {
                    Text(frame.recipe.name)
                        .font(.system(size: 31, weight: .black, design: .serif))
                        .foregroundStyle(LockroomPalette.paper)
                        .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                    Text(heroCaption)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LockroomPalette.paper.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Toggle(isOn: $revealDeveloped) {
                            Label("Developed", systemImage: "wand.and.rays")
                        }
                        .toggleStyle(.button)
                        .buttonStyle(.borderedProminent)
                        .tint(LockroomPalette.cinnabar)
                        .disabled(frame.developedImage == nil)

                        Text(frame.createdAt, style: .relative)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(LockroomPalette.fog)

                        Button {
                            onOpenDetail()
                        } label: {
                            Label("Details", systemImage: "slider.horizontal.below.rectangle")
                                .font(.system(size: 12, weight: .black))
                        }
                        .buttonStyle(.bordered)
                        .tint(LockroomPalette.paper)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.84), .black.opacity(0.52), .black.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
    }

    private var displayedImage: UIImage {
        revealDeveloped ? (frame.developedImage ?? frame.sourceImage) : frame.sourceImage
    }

    private var heroCaption: String {
        switch frame.status {
        case .queued:
            return "Queued for a premium photographic development pass."
        case .developing:
            return "GPT Image 2 is rebuilding color, detail, lens feel, and tonal balance."
        case .ready:
            return frame.recipe.toneRead
        case .failed(let message):
            return message
        }
    }
}

struct FrameRow: View {
    let frame: DevelopedFrame
    let onOpenDetail: () -> Void
    let onInspectImage: (InspectableFrameImage) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onInspectImage(frame.inspectableCurrentImage())
            } label: {
                Image(uiImage: frame.developedImage ?? frame.sourceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 82, height: 98)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LockroomPalette.paper)
                            .padding(6)
                            .background(.black.opacity(0.44), in: Circle())
                            .padding(5)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open frame full screen")

            Button {
                onOpenDetail()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(frame.recipe.name)
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(LockroomPalette.paper)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Image(systemName: frame.status.symbol)
                            Text(frame.status.title)
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                        Text(frame.source)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(LockroomPalette.fog)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(frame.createdAt, style: .relative)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(LockroomPalette.fog)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LockroomPalette.paper.opacity(0.55))
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open frame details")
        }
        .contentShape(Rectangle())
    }

    private var statusColor: Color {
        switch frame.status {
        case .queued:
            return LockroomPalette.gold
        case .developing:
            return LockroomPalette.cyan
        case .ready:
            return LockroomPalette.cinnabar
        case .failed:
            return .red
        }
    }
}

struct BeforeAfterStrip: View {
    let frame: DevelopedFrame
    let onInspectImage: (InspectableFrameImage) -> Void

    var body: some View {
        HStack(spacing: 10) {
            labeledImage(title: "Original", item: frame.inspectableOriginalImage())
            labeledImage(title: "Developed", item: frame.inspectableDevelopedImage())
        }
    }

    private func labeledImage(title: String, item: InspectableFrameImage) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(LockroomPalette.fog)
            Button {
                onInspectImage(item)
            } label: {
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 172)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.13), lineWidth: 1))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LockroomPalette.paper)
                            .padding(6)
                            .background(.black.opacity(0.44), in: Circle())
                            .padding(5)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(title.lowercased()) image full screen")
        }
    }
}

private struct StatusChip: View {
    let status: DevelopmentStatus

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: status.symbol)
            Text(status.title)
        }
        .font(.system(size: 13, weight: .black))
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(color.opacity(0.16))
                .overlay(Capsule().stroke(color.opacity(0.42)))
                .background(.black.opacity(0.25), in: Capsule())
        )
    }

    private var color: Color {
        switch status {
        case .queued:
            return LockroomPalette.gold
        case .developing:
            return LockroomPalette.cyan
        case .ready:
            return LockroomPalette.cinnabar
        case .failed:
            return .red
        }
    }
}

private struct SourceChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(LockroomPalette.paper)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.34))
                    .overlay(Capsule().stroke(.white.opacity(0.16)))
            )
    }
}
