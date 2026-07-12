import SwiftUI

struct ControlsPanel: View {
    @ObservedObject var extractor: FrameExtractor
    @State private var selectedFormat: ExportFormat = .png
    @State private var isExtracting = false
    @State private var showBatchSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color("Stroke"))

            VStack(spacing: 14) {
                // Timeline Scrubber
                TimelineScrubber(extractor: extractor)

                // Bottom row
                HStack(spacing: 12) {
                    // Frame stepper
                    HStack(spacing: 2) {
                        FrameStepButton(icon: "backward.frame.fill") {
                            extractor.stepFrame(forward: false)
                        }
                        FrameStepButton(icon: "forward.frame.fill") {
                            extractor.stepFrame(forward: true)
                        }
                    }

                    Spacer()

                    // Format picker
                    Picker("", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .colorScheme(.dark)

                    Spacer()

                    // Extract button
                    Button {
                        Task { await extractFrame() }
                    } label: {
                        HStack(spacing: 6) {
                            if isExtracting {
                                ProgressView().scaleEffect(0.7).tint(.black)
                            } else {
                                Image(systemName: "camera.fill")
                            }
                            Text(isExtracting ? "Extraindo…" : "Extrair Frame")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(TealButtonStyle())
                    .disabled(isExtracting)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color("Surface"))
        }
    }

    private func extractFrame() async {
        isExtracting = true
        _ = await extractor.extractCurrentFrame(format: selectedFormat)
        isExtracting = false
    }
}

// MARK: - Timeline Scrubber

struct TimelineScrubber: View {
    @ObservedObject var extractor: FrameExtractor

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color("Stroke"))
                        .frame(height: 4)

                    // Progress
                    Capsule()
                        .fill(Color("Teal"))
                        .frame(width: progress * geo.size.width, height: 4)

                    // Thumb
                    Circle()
                        .fill(Color("Teal"))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color("Teal").opacity(0.5), radius: 4)
                        .offset(x: progress * geo.size.width - 7)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let ratio = (value.location.x / geo.size.width).clamped(to: 0...1)
                                    extractor.seek(to: ratio * extractor.duration)
                                }
                        )
                }
                .frame(height: 14)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let ratio = (location.x / geo.size.width).clamped(to: 0...1)
                    extractor.seek(to: ratio * extractor.duration)
                }
            }
            .frame(height: 14)

            HStack {
                Text(formatTime(extractor.currentTime))
                    .monospacedDigit()
                Spacer()
                Text(formatTime(extractor.duration))
                    .monospacedDigit()
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(Color("TextSecondary"))
        }
    }

    private var progress: Double {
        guard extractor.duration > 0 else { return 0 }
        return extractor.currentTime / extractor.duration
    }

    private func formatTime(_ t: Double) -> String {
        let total = Int(t)
        let ms    = Int((t - Double(total)) * 1000)
        let m     = total / 60
        let s     = total % 60
        return String(format: "%02d:%02d.%03d", m, s, ms)
    }
}

// MARK: - Frame Step Button

struct FrameStepButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("TextPrimary"))
                .frame(width: 32, height: 28)
                .background(Color("Surface2"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Teal Button Style

struct TealButtonStyle: ButtonStyle {
    var small: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: small ? 12 : 13, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, small ? 12 : 16)
            .padding(.vertical, small ? 6 : 8)
            .background(
                Color("Teal")
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
