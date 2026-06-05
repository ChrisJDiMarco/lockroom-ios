import SwiftUI
import UIKit

enum DevelopmentStatus: Equatable {
    case queued
    case developing
    case ready
    case failed(String)

    var title: String {
        switch self {
        case .queued:
            return "Queued"
        case .developing:
            return "Developing"
        case .ready:
            return "Ready"
        case .failed:
            return "Needs attention"
        }
    }

    var symbol: String {
        switch self {
        case .queued:
            return "timer"
        case .developing:
            return "camera.filters"
        case .ready:
            return "checkmark.seal.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct DevelopedFrame: Identifiable {
    let id: UUID
    let sourceImage: UIImage
    var developedImage: UIImage?
    var status: DevelopmentStatus
    var createdAt: Date
    var completedAt: Date?
    var source: String
    var recipe: DevelopmentRecipe
}

struct DevelopmentRecipe {
    let name: String
    let lensRead: String
    let toneRead: String
    let outputIntent: String
    let accent: Color

    static let editorialPrime = DevelopmentRecipe(
        name: "Editorial Prime",
        lensRead: "85mm prime depth, corrected geometry",
        toneRead: "clean whites, lifted shadow detail, filmic contrast",
        outputIntent: "Make it feel expensive without changing the scene.",
        accent: LockroomPalette.cinnabar
    )
}
