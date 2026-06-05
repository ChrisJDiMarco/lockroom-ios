import Foundation
import UIKit

struct OpenAIImageEditClient: ImageDevelopmentService {
    let apiKey: String
    var session: URLSession = .lockroomImageEdits

    func develop(image: UIImage, prompt: String) async throws -> UIImage {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKey.isEmpty == false else {
            throw ImageDevelopmentError.invalidAPIKey
        }

        guard let imageData = image.normalizedForOpenAIUpload().jpegData(compressionQuality: 0.9) else {
            throw ImageDevelopmentError.missingImageData
        }

        guard imageData.count < 50 * 1024 * 1024 else {
            throw ImageDevelopmentError.imageTooLarge
        }

        var form = MultipartFormDataBuilder()
        form.appendField(name: "model", value: "gpt-image-2")
        form.appendField(name: "quality", value: "high")
        form.appendField(name: "size", value: "auto")
        form.appendField(name: "output_format", value: "jpeg")
        form.appendField(name: "output_compression", value: "92")
        form.appendField(name: "moderation", value: "auto")
        form.appendField(name: "prompt", value: prompt)
        form.appendFile(name: "image[]", filename: "lockroom-source.jpg", mimeType: "image/jpeg", data: imageData)

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/edits")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(form.boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Client-Request-Id")
        request.httpBody = form.finalizedBody()

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) == false {
            let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
            let requestID = httpResponse.value(forHTTPHeaderField: "x-request-id")
            let message = apiError?.error.message ?? "OpenAI request failed with HTTP \(httpResponse.statusCode)."
            throw ImageDevelopmentError.apiFailure([message, requestID.map { "Request \($0)" }].compactMap { $0 }.joined(separator: " "))
        }

        let decoded = try JSONDecoder().decode(OpenAIImageResponse.self, from: data)
        guard
            let base64 = decoded.data.first?.b64JSON,
            let bytes = Data(base64Encoded: base64),
            let image = UIImage(data: bytes)
        else {
            throw ImageDevelopmentError.invalidResponse
        }

        return image
    }
}

private extension URLSession {
    static let lockroomImageEdits: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 240
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()
}

private extension UIImage {
    func normalizedForOpenAIUpload(maxLongEdge: CGFloat = 3072) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxLongEdge else {
            return normalizedOrientation()
        }

        let scale = maxLongEdge / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            normalizedOrientation().draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

private struct OpenAIImageResponse: Decodable {
    struct Item: Decodable {
        let b64JSON: String?

        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
        }
    }

    let data: [Item]
}

private struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}
