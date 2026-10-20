import SwiftUI
import Jump

/// Stega genom videon bild för bild och markera hoppet. METOD M5
struct ReviewView: View {
    let url: URL

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var video: VideoFrames?
    @State private var loadProblem: String?
    @State private var frame = 0
    @State private var image: CGImage?
    @State private var imageTask: Task<Void, Never>?
    @State private var firstAir: Int?
    @State private var landing: Int?
    @State private var style: JumpStyle = .handsOnHips
    @State private var massText = ""
    @State private var saved = 0

    var body: some View {
        NavigationStack {
            Group {
                if let video {
                    content(video)
                } else if let loadProblem {
                    ContentUnavailableView(loadProblem, systemImage: "video.slash")
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { close() }
                }
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private func content(_ video: VideoFrames) -> some View {
        VStack(spacing: 12) {
            frameImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text("Bild \(frame + 1) av \(video.clock.count) · \(Int(video.clock.frameRate)) bilder/s")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Slider(value: Binding(get: { Double(frame) }, set: { go(to: Int($0.rounded())) }),
                   in: 0...Double(max(video.clock.count - 1, 1)))
            HStack {
                step(-10, "backward.fill")
                step(-1, "backward.frame.fill")
                step(1, "forward.frame.fill")
                step(10, "forward.fill")
            }
            HStack {
                markButton("Första i luften", value: firstAir) { firstAir = frame }
                markButton("Första på marken", value: landing) { landing = frame }
            }
            Picker("Sort", selection: $style) {
                Text("Händer på höfterna").tag(JumpStyle.handsOnHips)
                Text("Armsving").tag(JumpStyle.armSwing)
            }
            .pickerStyle(.segmented)
            outcome(video)
        }
        .padding()
    }

    private var frameImage: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1).resizable().scaledToFit()
            } else {
                Color.black
            }
        }
    }

    private func step(_ n: Int, _ symbol: String) -> some View {
        Button { go(to: frame + n) } label: {
            Image(systemName: symbol).frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.bordered)
        .buttonRepeatBehavior(.enabled)
    }

    private func markButton(_ title: String, value: Int?, set: @escaping () -> Void) -> some View {
        Button(action: set) {
            VStack(spacing: 2) {
                Text(title).font(.subheadline)
                Text(value.map { "bild \($0 + 1)" } ?? "–").font(.caption).monospacedDigit()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(value == nil ? Color.accentColor : Color.green)
        .contextMenu {
            if let value { Button("Gå till bild \(value + 1)") { go(to: value) } }
        }
    }

    @ViewBuilder
    private func outcome(_ video: VideoFrames) -> some View {
        if let firstAir, let landing {
            let marking = FlightMarking(firstAirFrame: firstAir, landingFrame: landing)
            switch Result(catching: { try video.clock.flightTime(marking) }) {
            case let .success(t):
                if let mass = store.history.bodyMassKg {
                    ResultSummary(result: JumpResult(flightTime: t, frameInterval: video.clock.frameInterval,
                                                     massKg: mass))
                    Button(saved == 0 ? "Spara" : "Spara (\(saved) sparade)") { save(t, marking, video, mass) }
                        .buttonStyle(.borderedProminent)
                } else {
                    massField
                }
            case let .failure(error):
                Text(Self.text(for: error)).font(.callout).foregroundStyle(.orange)
            }
        } else if saved > 0 {
            Text("\(saved) sparade. Markera nästa hopp eller tryck Klar.").font(.callout).foregroundStyle(.secondary)
        }
    }

    private var massField: some View {
        HStack {
            TextField("Vikt i kg", text: $massText).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
            Button("Spara vikt") {
                if let kg = Double(massText.replacingOccurrences(of: ",", with: ".")), kg > 20, kg < 250 {
                    store.setBodyMass(kg)
                }
            }
        }
    }

    static func text(for error: Error) -> String {
        switch error as? MarkingError {
        case .landingNotAfterTakeoff: return "Landningen måste komma efter avstampet."
        case .tooShort: return "För kort tid i luften. Kontrollera markeringarna."
        case .tooLong: return "För lång tid i luften. Är videon omsparad med nedsaktningen inbakad? Välj originalet."
        default: return "Markeringen ligger utanför videon."
        }
    }

    private func load() async {
        do {
            let v = try await VideoFrames.load(url)
            video = v
            go(to: 0)
        } catch {
            loadProblem = error.localizedDescription
        }
    }

    private func go(to index: Int) {
        guard let video else { return }
        let i = min(max(index, 0), video.clock.count - 1)
        frame = i
        imageTask?.cancel()
        imageTask = Task {
            guard let img = try? await video.image(at: i), !Task.isCancelled, frame == i else { return }
            image = img
        }
    }

    private func save(_ t: Double, _ marking: FlightMarking, _ video: VideoFrames, _ mass: Double) {
        store.add(JumpAttempt(recordedAt: video.recordedAt ?? Date(), style: style, massKg: mass, flightTime: t,
                              frameInterval: video.clock.frameInterval, marking: marking,
                              videoFileName: url.lastPathComponent))
        saved += 1
        firstAir = nil
        landing = nil
    }

    private func close() {
        imageTask?.cancel()
        store.deleteVideoIfUnused(url)
        dismiss()
    }
}

/// Ett hopps siffror.
struct ResultSummary: View {
    let result: JumpResult

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
                Text("Höjd")
                Text("\(Format.cm(result.height)) ± \(Format.cm(result.heightUncertainty)) cm").bold()
            }
            GridRow {
                Text("Impuls")
                Text("\(Format.whole(result.impulse)) N·s")
            }
            GridRow {
                Text("Effekt")
                Text("\(Format.whole(result.peakPower)) W")
            }
            GridRow {
                Text("I luften")
                Text("\(Format.ms(result.flightTime)) ms")
            }
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum Format {
    static func cm(_ meters: Double) -> String {
        (meters * 100).formatted(.number.precision(.fractionLength(1)))
    }

    static func whole(_ x: Double) -> String {
        x.formatted(.number.precision(.fractionLength(0)))
    }

    static func ms(_ seconds: Double) -> String {
        (seconds * 1000).formatted(.number.precision(.fractionLength(0)))
    }

    static func percent(_ change: Double) -> String {
        (change * 100).formatted(.number.precision(.fractionLength(0)).sign(strategy: .always()))
    }
}
