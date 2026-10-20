import SwiftUI

/// Inspelning, och direkt därefter granskningen av samma video.
struct RecordFlow: View {
    @State private var recorded: URL?

    var body: some View {
        if let recorded {
            ReviewView(url: recorded)
        } else {
            RecordView { recorded = $0 }
        }
    }
}

struct RecordView: View {
    var onFinished: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraRecorder()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreview(session: camera.session).ignoresSafeArea()
            VStack {
                HStack {
                    Button("Avbryt") {
                        camera.stop()
                        dismiss()
                    }
                    Spacer()
                    if camera.frameRate > 0 {
                        Text("\(camera.frameRate) bilder/s").monospacedDigit()
                    }
                }
                .padding()
                .foregroundStyle(.white)
                Spacer()
                if let problem = camera.problem {
                    Text(problem).foregroundStyle(.white).padding().background(.red.opacity(0.8), in: .rect(cornerRadius: 8))
                }
                Button { camera.toggleRecording() } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 4).frame(width: 76, height: 76)
                        RoundedRectangle(cornerRadius: camera.isRecording ? 6 : 31)
                            .fill(.red)
                            .frame(width: camera.isRecording ? 30 : 62, height: camera.isRecording ? 30 : 62)
                    }
                }
                .disabled(camera.frameRate == 0)
                .padding(.bottom, 24)
            }
        }
        .task { await camera.start() }
        .onChange(of: camera.finished) { _, url in
            guard let url else { return }
            camera.stop()
            onFinished(url)
        }
        .onDisappear { camera.stop() }
    }
}
