import XCTest
@testable import Lockroom

final class DevelopmentPromptTests: XCTestCase {
    func testPromptPreservesSceneInsteadOfInventingNewContent() {
        let prompt = DevelopmentPrompt.makePrompt(recipe: .editorialPrime)

        XCTAssertTrue(prompt.contains("Preserve the real subject"))
        XCTAssertTrue(prompt.contains("Do not invent new objects"))
        XCTAssertTrue(prompt.contains("premium photographic development pass"))
    }

    func testMultipartBuilderIncludesModelPromptAndImageFile() {
        var builder = MultipartFormDataBuilder(boundary: "TestBoundary")
        builder.appendField(name: "model", value: "gpt-image-2")
        builder.appendField(name: "prompt", value: "Improve this photo")
        builder.appendFile(name: "image[]", filename: "frame.jpg", mimeType: "image/jpeg", data: Data([1, 2, 3]))

        let body = String(decoding: builder.finalizedBody(), as: UTF8.self)

        XCTAssertTrue(body.contains("name=\"model\""))
        XCTAssertTrue(body.contains("gpt-image-2"))
        XCTAssertTrue(body.contains("name=\"prompt\""))
        XCTAssertTrue(body.contains("filename=\"frame.jpg\""))
        XCTAssertTrue(body.contains("Content-Type: image/jpeg"))
        XCTAssertTrue(body.contains("--TestBoundary--"))
    }
}

