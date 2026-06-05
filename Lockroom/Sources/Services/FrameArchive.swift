import Foundation
import UIKit

enum FrameArchive {
    private static let maxFrames = 20
    private static let manifestName = "frames.json"

    static func load() -> [DevelopedFrame] {
        guard
            let data = try? Data(contentsOf: manifestURL)
        else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let records = try? decoder.decode([FrameRecord].self, from: data) else {
            return []
        }

        return records.compactMap { record in
            guard let sourceImage = UIImage(contentsOfFile: imagesDirectory.appendingPathComponent(record.sourceFile).path) else {
                return nil
            }

            let developedImage = record.developedFile.flatMap {
                UIImage(contentsOfFile: imagesDirectory.appendingPathComponent($0).path)
            }

            return DevelopedFrame(
                id: record.id,
                sourceImage: sourceImage,
                developedImage: developedImage,
                status: record.status.frameStatus,
                createdAt: record.createdAt,
                completedAt: record.completedAt,
                source: record.source,
                recipe: .editorialPrime
            )
        }
    }

    static func save(_ frames: [DevelopedFrame]) {
        do {
            try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            let records = try frames.prefix(maxFrames).map(writeRecord(for:))
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: manifestURL, options: [.atomic])
            removeUnreferencedImages(keeping: Set(records.flatMap { [$0.sourceFile, $0.developedFile].compactMap { $0 } }))
        } catch {
            // Persistence should never interrupt the capture-to-develop workflow.
        }
    }

    private static func writeRecord(for frame: DevelopedFrame) throws -> FrameRecord {
        let sourceFile = "\(frame.id.uuidString)-source.jpg"
        try write(image: frame.sourceImage, filename: sourceFile)

        let developedFile: String?
        if let developedImage = frame.developedImage {
            let filename = "\(frame.id.uuidString)-developed.jpg"
            try write(image: developedImage, filename: filename)
            developedFile = filename
        } else {
            developedFile = nil
        }

        return FrameRecord(
            id: frame.id,
            sourceFile: sourceFile,
            developedFile: developedFile,
            status: .init(frame.status),
            createdAt: frame.createdAt,
            completedAt: frame.completedAt,
            source: frame.source,
            recipe: frame.recipe.name
        )
    }

    private static func write(image: UIImage, filename: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw ImageDevelopmentError.missingImageData
        }
        try data.write(to: imagesDirectory.appendingPathComponent(filename), options: [.atomic])
    }

    private static func removeUnreferencedImages(keeping filenames: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files where filenames.contains(file.lastPathComponent) == false {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static var rootDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lockroom", isDirectory: true)
    }

    private static var imagesDirectory: URL {
        rootDirectory.appendingPathComponent("Frames", isDirectory: true)
    }

    private static var manifestURL: URL {
        rootDirectory.appendingPathComponent(manifestName)
    }
}

private struct FrameRecord: Codable {
    let id: UUID
    let sourceFile: String
    let developedFile: String?
    let status: StatusRecord
    let createdAt: Date
    let completedAt: Date?
    let source: String
    let recipe: String
}

private struct StatusRecord: Codable {
    let name: String
    let message: String?

    init(_ status: DevelopmentStatus) {
        switch status {
        case .queued:
            name = "queued"
            message = nil
        case .developing:
            name = "developing"
            message = nil
        case .ready:
            name = "ready"
            message = nil
        case .failed(let error):
            name = "failed"
            message = error
        }
    }

    var frameStatus: DevelopmentStatus {
        switch name {
        case "queued":
            return .queued
        case "developing":
            return .developing
        case "ready":
            return .ready
        case "failed":
            return .failed(message ?? "Development failed.")
        default:
            return .failed("Unknown archived state.")
        }
    }
}
