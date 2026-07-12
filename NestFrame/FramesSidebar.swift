import SwiftUI

struct FramesSidebar: View {
    @ObservedObject var extractor: FrameExtractor

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Frames Extraídos")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color("TextSecondary"))

                Spacer()

                if !extractor.exportedFrames.isEmpty {
                    Button {
                        extractor.clearFrames()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .buttonStyle(.plain)
                    .help("Limpar todos os frames")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color("Surface"))
            .overlay(alignment: .bottom) {
                Divider().background(Color("Stroke"))
            }

            // List
            if extractor.exportedFrames.isEmpty {
                EmptyFramesPlaceholder()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(extractor.exportedFrames) { frame in
                            FrameCard(frame: frame) {
                                extractor.saveFrame(frame)
                            } onRemove: {
                                extractor.removeFrame(id: frame.id)
                            } onSeek: {
                                extractor.seek(to: frame.timestamp)
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(Color("SidebarBG"))
    }
}

// MARK: - Empty Placeholder

struct EmptyFramesPlaceholder: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.badge.clock")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Nenhum frame extraído")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("TextSecondary").opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Frame Card

struct FrameCard: View {
    let frame: ExtractedFrame
    let onSave: () -> Void
    let onRemove: () -> Void
    let onSeek: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                Image(nsImage: frame.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 130)
                    .clipped()
                    .onTapGesture { onSeek() }

                // Format badge
                Text(frame.format.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color("Teal"))
                    .clipShape(Capsule())
                    .padding(6)
            }

            // Meta
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(Color("Teal"))
                    Text(frame.formattedTimestamp)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color("TextPrimary"))

                    Spacer()

                    Text(frame.resolutionLabel)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color("TextSecondary"))
                }

                HStack(spacing: 6) {
                    // Save
                    Button {
                        onSave()
                    } label: {
                        Label("Salvar", systemImage: "square.and.arrow.down")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(GhostButtonStyle())

                    Spacer()

                    // Remove
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .buttonStyle(.plain)
                    .help("Remover")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color("Stroke"), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

// MARK: - Ghost Button Style

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color("Teal"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Color("Teal")
                    .opacity(configuration.isPressed ? 0.15 : 0.08)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
