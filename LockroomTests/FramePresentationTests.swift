import UIKit
import XCTest
@testable import Lockroom

final class FramePresentationTests: XCTestCase {
    func testInspectableCurrentImagePrefersDevelopedFrameWhenAvailable() {
        let source = makeImage(color: .red)
        let developed = makeImage(color: .blue)
        let frame = makeFrame(source: source, developed: developed)

        let item = frame.inspectableCurrentImage()

        XCTAssertEqual(item.title, "Developed Frame")
        XCTAssertEqual(item.subtitle, DevelopmentRecipe.editorialPrime.name)
        XCTAssertTrue(item.canSave)
        XCTAssertEqual(item.image.pngData(), developed.pngData())
    }

    func testInspectableCurrentImageFallsBackToOriginalBeforeDevelopment() {
        let source = makeImage(color: .red)
        let frame = makeFrame(source: source, developed: nil)

        let item = frame.inspectableCurrentImage()

        XCTAssertEqual(item.title, "Original Frame")
        XCTAssertEqual(item.subtitle, "Chosen photo")
        XCTAssertFalse(item.canSave)
        XCTAssertEqual(item.image.pngData(), source.pngData())
    }

    func testInspectableSelectedPhotoIsNotSaveableBeforeDevelopment() {
        let source = makeImage(color: .red)

        let item = InspectableFrameImage.selectedPhoto(image: source)

        XCTAssertEqual(item.title, "Selected Photo")
        XCTAssertEqual(item.subtitle, "Ready for GPT Image 2")
        XCTAssertFalse(item.canSave)
        XCTAssertEqual(item.image.pngData(), source.pngData())
    }

    private func makeFrame(source: UIImage, developed: UIImage?) -> DevelopedFrame {
        DevelopedFrame(
            id: UUID(),
            sourceImage: source,
            developedImage: developed,
            status: developed == nil ? .developing : .ready,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            completedAt: developed == nil ? nil : Date(timeIntervalSince1970: 1_800_000_060),
            source: "Chosen photo",
            recipe: .editorialPrime
        )
    }

    private func makeImage(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }
}
