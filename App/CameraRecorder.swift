import AVFoundation
import Observation
import SwiftUI
import UIKit

/// Bakre kameran i högsta bildfrekvensen den klarar, upp till 240 bilder/s. METOD M7
@Observable
final class CameraRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private let queue = DispatchQueue(label: "hopp.kamera")

    var isRecording = false
    var frameRate = 0
    var problem: String?
    /// Sätts när en inspelning är klar och sparad.
    var finished: URL?

    static let wantedRate = 240.0

    @MainActor
    func start() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            problem = "Hopp får inte använda kameran. Slå på den under Inställningar → Hopp."
            return
        }
        queue.async { [self] in
            do {
                let rate = try configure()
                session.startRunning()
                DispatchQueue.main.async { self.frameRate = rate }
            } catch {
                DispatchQueue.main.async { self.problem = "Kameran gick inte att starta." }
            }
        }
    }

    func stop() {
        queue.async { [self] in
            if output.isRecording { output.stopRecording() }
            session.stopRunning()
        }
    }

    func toggleRecording() {
        if isRecording {
            queue.async { [self] in output.stopRecording() }
            return
        }
        let url = Store.videos.appending(path: "\(UUID().uuidString).mov")
        isRecording = true
        queue.async { [self] in output.startRecording(to: url, recordingDelegate: self) }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        let ok = error == nil
            || ((error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false)
        DispatchQueue.main.async {
            self.isRecording = false
            if ok { self.finished = url } else { self.problem = "Inspelningen misslyckades." }
        }
    }

    /// Körs på `queue`. Returnerar bildfrekvensen som ställdes in.
    private func configure() throws -> Int {
        if let input = session.inputs.first as? AVCaptureDeviceInput {
            return Int(input.device.activeVideoMinFrameDuration.timescale)
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCamera
        }
        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canAddInput(input), session.canAddOutput(output) else { throw CameraError.noCamera }
        session.addInput(input)
        session.addOutput(output)

        var rate = 30
        if let best = Self.fastestFormat(device.formats) {
            let format = best.0
            rate = Int(min(best.1, Self.wantedRate))
            try device.lockForConfiguration()
            device.activeFormat = format
            let d = CMTime(value: 1, timescale: CMTimeScale(rate))
            device.activeVideoMinFrameDuration = d
            device.activeVideoMaxFrameDuration = d
            device.unlockForConfiguration()
        }
        if let c = output.connection(with: .video) {
            if c.isVideoRotationAngleSupported(90) { c.videoRotationAngle = 90 }
            if c.isVideoStabilizationSupported { c.preferredVideoStabilizationMode = .off }
        }
        return rate
    }

    /// Formatet med högst bildfrekvens (högst 240), och vid lika den största bilden upp till 1080p.
    static func fastestFormat(_ formats: [AVCaptureDevice.Format]) -> (AVCaptureDevice.Format, Double)? {
        func score(_ f: AVCaptureDevice.Format) -> (Double, Int32) {
            let rate = min(f.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0, Self.wantedRate)
            let dims = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
            let pixels = dims.width <= 1920 ? dims.width * dims.height : 0
            return (rate, pixels)
        }
        guard let best = formats.max(by: { score($0) < score($1) }) else { return nil }
        return (best, score(best).0)
    }

    enum CameraError: Error { case noCamera }
}

/// Kamerans bild på skärmen.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        if let c = view.previewLayer.connection, c.isVideoRotationAngleSupported(90) { c.videoRotationAngle = 90 }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
