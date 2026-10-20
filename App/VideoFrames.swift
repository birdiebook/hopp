import AVFoundation
import CoreGraphics
import Jump

/// En videos bilder: deras tider ur filen och bilden för varje index. METOD M5
final class VideoFrames {
    let times: [CMTime]
    let clock: FrameClock
    /// När videon spelades in, om filen säger det.
    let recordedAt: Date?
    private let generator: AVAssetImageGenerator
    /// Små bilder till filmremsan, egen generator så att de inte köar bakom den stora bilden.
    private let thumbnails: AVAssetImageGenerator

    private init(asset: AVURLAsset, times: [CMTime], recordedAt: Date?) {
        self.times = times
        self.clock = FrameClock(times: times.map(\.seconds))
        self.recordedAt = recordedAt
        generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // Exakt den bild som efterfrågas, aldrig närmaste nyckelbild.
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 1280, height: 1280)
        thumbnails = AVAssetImageGenerator(asset: asset)
        thumbnails.appliesPreferredTrackTransform = true
        thumbnails.requestedTimeToleranceBefore = .zero
        thumbnails.requestedTimeToleranceAfter = .zero
        thumbnails.maximumSize = CGSize(width: 160, height: 160)
    }

    enum LoadError: LocalizedError {
        case noVideo, noFrames
        var errorDescription: String? {
            switch self {
            case .noVideo: return "Filen har ingen video."
            case .noFrames: return "Videon har för få bilder."
            }
        }
    }

    /// Läser varje bilds visningstid. Bilderna avkodas inte, så det går fort även för 240 bilder/s.
    static func load(_ url: URL) async throws -> VideoFrames {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw LoadError.noVideo }
        let created = try? await asset.load(.creationDate)
        // try? på ett Date? ger Date??, därför ?? nil.
        let recordedAt: Date? = (try? await created?.load(.dateValue)) ?? nil
        let times = try await Task.detached(priority: .userInitiated) {
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
            output.alwaysCopiesSampleData = false
            reader.add(output)
            reader.startReading()
            var times: [CMTime] = []
            while let buffer = output.copyNextSampleBuffer() {
                if CMSampleBufferGetNumSamples(buffer) > 0 {
                    times.append(CMSampleBufferGetPresentationTimeStamp(buffer))
                }
            }
            return times.sorted { CMTimeCompare($0, $1) < 0 }
        }.value
        guard times.count > 2 else { throw LoadError.noFrames }
        return VideoFrames(asset: asset, times: times, recordedAt: recordedAt)
    }

    func image(at index: Int) async throws -> CGImage {
        try await generator.image(at: times[index]).image
    }

    func thumbnail(at index: Int) async throws -> CGImage {
        try await thumbnails.image(at: times[index]).image
    }
}
