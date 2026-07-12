import SwiftUI

struct ContentView: View {
    @StateObject private var extractor = FrameExtractor()
    @State private var isDragging = false

    var body: some View {
        HStack(spacing: 0) {
            // Left: Video + Controls
            VStack(spacing: 0) {
                TitleBar()
                VideoDropZone(extractor: extractor, isDragging: $isDragging)
                if extractor.videoURL != nil {
                    ControlsPanel(extractor: extractor)
                }
            }
            .frame(minWidth: 520)

            // Divider
            Divider()
                .background(Color("Stroke"))

            // Right: Extracted Frames
            FramesSidebar(extractor: extractor)
                .frame(width: 280)
        }
        .background(Color("BG"))
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  isVideoFile(url) else { return }
            DispatchQueue.main.async {
                extractor.loadVideo(url: url)
            }
        }
        return true
    }

    private func isVideoFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "avi", "mkv", "webm", "mts", "m2ts"].contains(ext)
    }
}
