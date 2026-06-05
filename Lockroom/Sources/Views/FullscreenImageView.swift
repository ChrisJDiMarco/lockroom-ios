import SwiftUI
import UIKit

struct InspectableFrameImage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let image: UIImage
    let canSave: Bool
}

extension InspectableFrameImage {
    static func selectedPhoto(image: UIImage) -> InspectableFrameImage {
        InspectableFrameImage(
            title: "Selected Photo",
            subtitle: "Ready for GPT Image 2",
            image: image,
            canSave: false
        )
    }
}

extension DevelopedFrame {
    func inspectableCurrentImage(showDeveloped: Bool = true) -> InspectableFrameImage {
        if showDeveloped, let developedImage {
            return inspectableDevelopedImage()
        }
        return inspectableOriginalImage()
    }

    func inspectableOriginalImage() -> InspectableFrameImage {
        InspectableFrameImage(
            title: "Original Frame",
            subtitle: source,
            image: sourceImage,
            canSave: false
        )
    }

    func inspectableDevelopedImage() -> InspectableFrameImage {
        InspectableFrameImage(
            title: developedImage == nil ? "Original Frame" : "Developed Frame",
            subtitle: recipe.name,
            image: developedImage ?? sourceImage,
            canSave: developedImage != nil
        )
    }
}

struct FullscreenImageView: View {
    let item: InspectableFrameImage
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(zoomGesture.simultaneously(with: panGesture))
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                        if scale > 1 {
                            resetTransform()
                        } else {
                            scale = 2.4
                            lastScale = scale
                        }
                    }
                }
                .accessibilityLabel(item.title)

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
        }
        .statusBarHidden()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LockroomPalette.paper)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Close image")

            Spacer()

            if item.canSave, let onSave {
                Button {
                    onSave()
                } label: {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(LockroomPalette.paper)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Save developed image")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(LockroomPalette.paper)
            Text(item.subtitle)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(LockroomPalette.fog)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.74), .black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 5)
                if scale == 1 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
            .onEnded { _ in
                if scale < 1.05 {
                    resetTransform()
                } else {
                    lastScale = scale
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func resetTransform() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}
