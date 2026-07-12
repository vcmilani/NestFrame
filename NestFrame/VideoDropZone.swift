import SwiftUI
import UniformTypeIdentifiers

struct VideoDropZone: View {
    @ObservedObject var extractor: FrameExtractor
    @Binding var isDragging: Bool

    var body: some View {
        ZStack {
            Color("BG")

            if let img = extractor.previewImage {
                // Frame Preview
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topTrailing) {
                        MetaBadge(extractor: extractor)
                            .padding(12)
                    }
            } else if extractor.isLoading {
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color("Teal"))
                    Text("Carregando vídeo…")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color("TextSecondary"))
                }
            } else {
                DropPrompt(isDragging: isDragging, onOpen: openFile)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(Rectangle())
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .mpeg4Movie, .quickTimeMovie]
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            extractor.loadVideo(url: url)
        }
    }
}

// MARK: - Drop Prompt

struct DropPrompt: View {
    let isDragging: Bool
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDragging ? Color("Teal") : Color("Stroke"),
                        style: StrokeStyle(lineWidth: 1.5, dash: isDragging ? [] : [6, 4])
                    )
                    .frame(width: 180, height: 120)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)

                Image(systemName: isDragging ? "arrow.down.circle.fill" : "film")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(isDragging ? Color("Teal") : Color("TextSecondary"))
                    .animation(.spring(response: 0.3), value: isDragging)
            }

            VStack(spacing: 6) {
                Text(isDragging ? "Solte para abrir" : "Arraste um vídeo aqui")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextPrimary"))

                if !isDragging {
                    Button("Escolher arquivo…") { onOpen() }
                        .buttonStyle(TealButtonStyle(small: true))
                }
            }

            if !isDragging {
                Text("MP4 · MOV · MKV · AVI · WebM")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color("TextSecondary").opacity(0.7))
            }
        }
    }
}

// MARK: - Meta Badge

struct MetaBadge: View {
    @ObservedObject var extractor: FrameExtractor

    var body: some View {
        HStack(spacing: 6) {
            if extractor.resolution != .zero {
                label("\(Int(extractor.resolution.width))×\(Int(extractor.resolution.height))")
            }
            if extractor.fps > 0 {
                label(String(format: "%.2f fps", extractor.fps))
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(Color("TextPrimary"))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
