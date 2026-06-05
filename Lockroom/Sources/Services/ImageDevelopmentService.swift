import Foundation
import UIKit

enum ImageDevelopmentError: LocalizedError {
    case missingImageData
    case invalidAPIKey
    case invalidResponse
    case imageTooLarge
    case photosPermissionRequired
    case noLatestPhoto
    case saveToPhotosFailed
    case apiFailure(String)

    var errorDescription: String? {
        switch self {
        case .missingImageData:
            return "Could not prepare the image."
        case .invalidAPIKey:
            return "Add an OpenAI API key before developing photos."
        case .invalidResponse:
            return "The image service returned an unexpected response."
        case .imageTooLarge:
            return "The image is larger than the 50 MB API limit."
        case .photosPermissionRequired:
            return "Allow Photos access before running the Camera-close automation."
        case .noLatestPhoto:
            return "No recent photo was found in Photos."
        case .saveToPhotosFailed:
            return "Could not save the developed frame to Photos."
        case .apiFailure(let message):
            return message
        }
    }
}

protocol ImageDevelopmentService {
    func develop(image: UIImage, prompt: String) async throws -> UIImage
}
