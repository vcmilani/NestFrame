import AppKit
import UniformTypeIdentifiers

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case png  = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"
    case webp = "WebP"

    var id: String { rawValue }

    var utType: UTType {
        switch self {
        case .png:  return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        case .webp: return UTType(filenameExtension: "webp") ?? .png
        }
    }

    var fileExtension: String {
        switch self {
        case .png:  return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        case .webp: return "webp"
        }
    }
}

// MARK: - Extracted Frame

struct ExtractedFrame: Identifiable {
    let id = UUID()
    let image: NSImage
    let timestamp: Double
    let format: ExportFormat
    let resolution: CGSize

    var suggestedFilename: String {
        let ts = String(format: "%.3f", timestamp).replacingOccurrences(of: ".", with: "_")
        return "frame_\(ts)s.\(format.fileExtension)"
    }

    var formattedTimestamp: String {
        let total = Int(timestamp)
        let ms    = Int((timestamp - Double(total)) * 1000)
        let h     = total / 3600
        let m     = (total % 3600) / 60
        let s     = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d.%03d", h, m, s, ms)
        } else {
            return String(format: "%02d:%02d.%03d", m, s, ms)
        }
    }

    var resolutionLabel: String {
        "\(Int(resolution.width))×\(Int(resolution.height))"
    }

    func data(for format: ExportFormat) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        switch format {
        case .png:  return rep.representation(using: .png,  properties: [:])
        case .jpeg: return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
        case .tiff: return rep.representation(using: .tiff, properties: [:])
        case .webp: return rep.representation(using: .png,  properties: [:]) // fallback
        }
    }
}
