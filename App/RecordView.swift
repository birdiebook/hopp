import SwiftUI

/// Kameran: hjälplinje för golvet, bildfrekvensen och den röda knappen (BESLUT B13).
struct RecordView: View {
    var onFinished: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraRecorder()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreview(session: camera.session).ignoresSafeArea()

            GeometryReader { geo in
                let y = geo.size.height * 0.72
                Path { p in
                    p.move(to: .init(x: 20, y: y))
                    p.addLine(to: .init(x: geo.size.width - 20, y: y))
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
                Text("Golvet här")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .position(x: 70, y: y - 14)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            VStack {
                HStack {
                    Button("Avbryt") {
                        camera.stop()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(.black.opacity(0.55), in: .capsule)
                    Spacer()
                    if camera.frameRate > 0 {
                        HStack(spacing: 8) {
                            Circle().fill(camera.isRecording ? Theme.record : Theme.accent).frame(width: 8, height: 8)
                            Text("\(camera.frameRate) bilder/s").font(Theme.number(20)).monospacedDigit()
                        }
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(.black.opacity(0.55), in: .capsule)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                if let problem = camera.problem {
                    Text(problem)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Theme.record.opacity(0.85), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 20)
                }

                Button { camera.toggleRecording() } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 5).frame(width: 84, height: 84)
                        RoundedRectangle(cornerRadius: camera.isRecording ? 6 : 32)
                            .fill(Theme.record)
                            .frame(width: camera.isRecording ? 30 : 64, height: camera.isRecording ? 30 : 64)
                    }
                }
                .disabled(camera.frameRate == 0)
                .accessibilityLabel(camera.isRecording ? "Stoppa inspelningen" : "Starta inspelningen")
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await camera.start() }
        .onChange(of: camera.finished) { _, url in
            guard let url else { return }
            camera.stop()
            onFinished(url)
        }
        .onDisappear { camera.stop() }
    }
}
