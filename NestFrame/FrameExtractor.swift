import AVFoundation
import AppKit
import Combine

@MainActor
class FrameExtractor: ObservableObject {

    // MARK: - Published State

    @Published var videoURL: URL?
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var previewImage: NSImage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var fps: Double = 0
    @Published var resolution: CGSize = .zero
    @Published var exportedFrames: [ExtractedFrame] = []

    // MARK: - Private

    private var asset: AVAsset?
    /// Full-resolution generator — maximumSize = .zero (native pixels, no downscaling).
    private var imageGenerator: AVAssetImageGenerator?
    /// Preview-only generator — downscaled for fast scrubbing.
    private var previewGenerator: AVAssetImageGenerator?
    private var nativeSize: CGSize = .zero
    private var debounceCancellable: AnyCancellable?
    private let previewQueue = DispatchQueue(label: "com.framegrab.preview", qos: .userInitiated)

    // MARK: - Load Video

    func loadVideo(url: URL) {
        isLoading = true
        errorMessage = nil
        previewImage = nil
        exportedFrames = []
        imageGenerator = nil
        previewGenerator = nil
        nativeSize = .zero

        let asset = AVAsset(url: url)
        self.asset = asset

        Task {
            do {
                let duration = try await asset.load(.duration)
                let tracks = try await asset.loadTracks(withMediaType: .video)

                guard let videoTrack = tracks.first else {
                    await MainActor.run {
                        self.errorMessage = "Nenhuma faixa de vídeo encontrada."
                        self.isLoading = false
                    }
                    return
                }

                let naturalSize = try await videoTrack.load(.naturalSize)
                let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)

                // Compute the actual rendered size after applying track transform
                let preferredTransform = try await videoTrack.load(.preferredTransform)
                let transformedSize = naturalSize.applying(preferredTransform)
                let absSize = CGSize(
                    width:  abs(transformedSize.width),
                    height: abs(transformedSize.height)
                )
                // Use absSize if valid, else fall back to naturalSize
                let renderedSize = (absSize.width > 0 && absSize.height > 0) ? absSize : naturalSize

                // --- Full-resolution extractor (used when saving frames) ---
                // maximumSize = .zero means "no limit — return native pixel dimensions"
                let fullGen = AVAssetImageGenerator(asset: asset)
                fullGen.appliesPreferredTrackTransform = true
                fullGen.maximumSize = .zero          // ← key: forces native resolution
                fullGen.requestedTimeToleranceBefore = .zero
                fullGen.requestedTimeToleranceAfter  = .zero
                self.imageGenerator = fullGen

                // --- Preview generator (faster scrubbing, capped at 1280px wide) ---
                let previewGen = AVAssetImageGenerator(asset: asset)
                previewGen.appliesPreferredTrackTransform = true
                previewGen.maximumSize = CGSize(width: 1280, height: 720)
                previewGen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 10)
                previewGen.requestedTimeToleranceAfter  = CMTime(value: 1, timescale: 10)
                self.previewGenerator = previewGen
                self.nativeSize = renderedSize

                await MainActor.run {
                    self.videoURL = url
                    self.duration = duration.seconds
                    self.currentTime = 0
                    self.fps = Double(nominalFrameRate)
                    self.resolution = renderedSize   // post-transform native resolution
                    self.isLoading = false
                }

                await updatePreview(at: 0)

            } catch {
                await MainActor.run {
                    self.errorMessage = "Erro ao carregar vídeo: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Seek & Preview

    func seek(to time: Double) {
        currentTime = time
        schedulePreviewUpdate(at: time)
    }

    private func schedulePreviewUpdate(at time: Double) {
        debounceCancellable?.cancel()
        debounceCancellable = Just(time)
            .delay(for: .milliseconds(80), scheduler: RunLoop.main)
            .sink { [weak self] t in
                guard let self else { return }
                Task { await self.updatePreview(at: t) }
            }
    }

    func updatePreview(at time: Double) async {
        // Always use the preview generator for scrubbing — faster, lower memory
        guard let gen = previewGenerator else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        do {
            let (cgImage, _) = try await gen.image(at: cmTime)
            let nsImage = NSImage(cgImage: cgImage, size: .zero)
            await MainActor.run { self.previewImage = nsImage }
        } catch {
            // silently ignore scrub errors
        }
    }

    // MARK: - Step Frame

    func stepFrame(forward: Bool) {
        guard fps > 0 else { return }
        let delta = 1.0 / fps
        let newTime = (currentTime + (forward ? delta : -delta))
            .clamped(to: 0...duration)
        seek(to: newTime)
    }

    // MARK: - Extract Frame

    func extractCurrentFrame(format: ExportFormat) async -> ExtractedFrame? {
        guard let gen = imageGenerator else { return nil }

        let cmTime = CMTime(seconds: currentTime, preferredTimescale: 600)
        do {
            let (cgImage, actualTime) = try await gen.image(at: cmTime)
            let nsImage = NSImage(cgImage: cgImage, size: .zero)

            let frame = ExtractedFrame(
                image: nsImage,
                timestamp: actualTime.seconds,
                format: format,
                resolution: CGSize(width: cgImage.width, height: cgImage.height)
            )
            await MainActor.run {
                self.exportedFrames.insert(frame, at: 0)
            }
            return frame
        } catch {
            await MainActor.run {
                self.errorMessage = "Falha ao extrair frame: \(error.localizedDescription)"
            }
            return nil
        }
    }

    // MARK: - Save Frame

    func saveFrame(_ frame: ExtractedFrame) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = frame.suggestedFilename
        panel.allowedContentTypes = [frame.format.utType]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? frame.data(for: frame.format)?.write(to: url)
        }
    }

    // MARK: - Batch Export

    func extractFrames(times: [Double], format: ExportFormat) async -> [ExtractedFrame] {
        guard let gen = imageGenerator else { return [] }
        var results: [ExtractedFrame] = []

        for time in times {
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            if let (cgImage, actual) = try? await gen.image(at: cmTime) {
                let nsImage = NSImage(cgImage: cgImage, size: .zero)
                let frame = ExtractedFrame(
                    image: nsImage,
                    timestamp: actual.seconds,
                    format: format,
                    resolution: CGSize(width: cgImage.width, height: cgImage.height)
                )
                results.append(frame)
            }
        }

        await MainActor.run {
            self.exportedFrames.insert(contentsOf: results.reversed(), at: 0)
        }
        return results
    }

    func removeFrame(id: UUID) {
        exportedFrames.removeAll { $0.id == id }
    }

    func clearFrames() {
        exportedFrames.removeAll()
    }
}

// MARK: - Comparable clamped helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
