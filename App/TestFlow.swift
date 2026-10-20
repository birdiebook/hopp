import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import Jump

/// Ett test från uppställning till resultat (BESLUT B13). Uppställningen är roten,
/// och varje hopp går inspelning → granskning → resultat → tillbaka hit.
struct TestFlow: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Step] = []
    @State private var style: JumpStyle
    /// Videor som skapats under testet; de som inget hopp pekar på tas bort när testet stängs.
    @State private var videos: [URL] = []

    enum Step: Hashable {
        case record
        case review(URL)
        case result(UUID)
    }

    init(startStyle: JumpStyle) {
        _style = State(initialValue: startStyle)
    }

    var body: some View {
        NavigationStack(path: $path) {
            SetupView(style: $style,
                      number: number(for: style),
                      onRecord: { path.append(.record) },
                      onPicked: { url in
                          videos.append(url)
                          path.append(.review(url))
                      },
                      onClose: close)
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .record:
                        RecordView(onFinished: { url in
                            videos.append(url)
                            path = [.review(url)]
                        })
                    case let .review(url):
                        ReviewView(url: url, style: style) { id in path.append(.result(id)) }
                    case let .result(id):
                        ResultView(attemptID: id,
                                   onNext: next,
                                   onSameVideo: { path.removeLast() },
                                   onDone: close)
                    }
                }
        }
        .tint(Theme.accent)
    }

    private func number(for style: JumpStyle) -> Int {
        store.history.attempts.filter { $0.style == style && Calendar.current.isDateInToday($0.recordedAt) }.count + 1
    }

    private func next() {
        if let n = TestDay.next(store.history.attempts, on: Date(), calendar: .current) { style = n.style }
        path.removeAll()
    }

    private func close() {
        for v in videos { store.deleteVideoIfUnused(v) }
        dismiss()
    }
}

// MARK: - Uppställningen

struct SetupView: View {
    @Binding var style: JumpStyle
    let number: Int
    let onRecord: () -> Void
    let onPicked: (URL) -> Void
    let onClose: () -> Void

    @State private var picked: PhotosPickerItem?
    @State private var importing = false
    @State private var importProblem: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ställ upp telefonen").font(.system(size: 28, weight: .bold))
                Text(style == .armSwing ? "Svinga med armarna, landa på raka ben."
                                        : "Händerna på höfterna, landa på raka ben.")
                    .font(.system(size: 15)).foregroundStyle(Theme.secondary)
            }

            SetupIllustration()
                .frame(height: 230)
                .padding(.vertical, 8)
                .card(padding: 16)

            HStack(spacing: 10) {
                tile("2–3 m", "bort")
                tile("Fotled", "kamerans höjd")
                tile("240", "bilder/s")
            }

            Picker("Sort", selection: $style) {
                Text("CMJ").tag(JumpStyle.handsOnHips)
                Text("Armsving").tag(JumpStyle.armSwing)
            }
            .pickerStyle(.segmented)

            if let importProblem {
                Text(importProblem).font(.callout).foregroundStyle(Theme.warning)
            }

            Spacer(minLength: 0)

            Button("Starta kameran", action: onRecord).buttonStyle(PrimaryButtonStyle())
            // .current: originalfilen, så att en slow motion inte räknas om till 30 bilder/s. METOD M5
            PhotosPicker(selection: $picked, matching: .videos, preferredItemEncoding: .current) {
                Text(importing ? "Hämtar…" : "Välj video ur Bilder")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(importing)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.ground)
        .navigationTitle("\(style.name) · hopp \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Stäng", action: onClose)
            }
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            importing = true
            importProblem = nil
            Task {
                do {
                    if let movie = try await item.loadTransferable(type: PickedMovie.self) { onPicked(movie.url) }
                } catch {
                    importProblem = "Videon gick inte att hämta."
                }
                importing = false
                picked = nil
            }
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.number(26))
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(Theme.surface, in: .rect(cornerRadius: 16))
    }
}

/// En video vald ur Bilder, kopierad till appens videomapp.
struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let dest = Store.videos.appending(path: "\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return PickedMovie(url: dest)
        }
    }
}

// MARK: - Granskningen

/// Bild för bild: filmremsan, stegen och de två markeringarna. METOD M5
struct ReviewView: View {
    let url: URL
    let style: JumpStyle
    let onSaved: (UUID) -> Void

    @Environment(Store.self) private var store
    @State private var video: VideoFrames?
    @State private var loadProblem: String?
    @State private var frame = 0
    @State private var image: CGImage?
    @State private var imageTask: Task<Void, Never>?
    @State private var thumbs: [Int: CGImage] = [:]
    @State private var thumbTask: Task<Void, Never>?
    @State private var firstAir: Int?
    @State private var landing: Int?
    @State private var dragStart: Int?
    @State private var massText = ""

    private static let window = 4

    var body: some View {
        Group {
            if let video {
                content(video)
            } else if let loadProblem {
                ContentUnavailableView(loadProblem, systemImage: "video.slash")
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.ground)
        .navigationTitle(video == nil ? "" : "Bild \(frame + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: frame)
        .task { await load() }
        .onDisappear {
            imageTask?.cancel()
            thumbTask?.cancel()
        }
    }

    private func content(_ video: VideoFrames) -> some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image {
                        Image(decorative: image, scale: 1).resizable().scaledToFit()
                    } else {
                        Theme.surface
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.surface)
                .clipShape(.rect(cornerRadius: 20))
                Text("\(Int(video.clock.frameRate)) bilder/s")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.black.opacity(0.55), in: .capsule)
                    .padding(10)
            }
            .contentShape(.rect)
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { v in
                    if dragStart == nil { dragStart = frame }
                    go(to: (dragStart ?? frame) + Int(v.translation.width / 8))
                }
                .onEnded { _ in dragStart = nil })
            .accessibilityLabel("Bild \(frame + 1) av \(video.clock.count). Dra i sidled för att stega.")

            filmstrip(video)

            HStack(spacing: 8) {
                step(-10, "−10")
                step(-1, "−1")
                step(1, "+1")
                step(10, "+10")
            }

            HStack(spacing: 10) {
                markButton("Första i luften", value: firstAir) { firstAir = frame }
                markButton("Första på marken", value: landing) { landing = frame }
            }

            bottom(video)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func filmstrip(_ video: VideoFrames) -> some View {
        let range = visibleRange(video)
        return HStack(spacing: 6) {
            ForEach(Array(range), id: \.self) { i in
                Button { go(to: i) } label: {
                    VStack(spacing: 3) {
                        Group {
                            if let t = thumbs[i] {
                                Image(decorative: t, scale: 1).resizable().scaledToFill()
                            } else {
                                Theme.raised
                            }
                        }
                        .frame(width: 32, height: 50)
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(i == frame ? Theme.accent : .clear, lineWidth: 2))
                        Text(i == firstAir ? "L" : (i == landing ? "M" : " "))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Bild \(i + 1)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func step(_ n: Int, _ title: String) -> some View {
        Button { go(to: frame + n) } label: {
            Text(title).font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 48)
        }
        .foregroundStyle(Theme.text)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(n > 0 ? "\(n) bilder framåt" : "\(-n) bilder bakåt")
    }

    private func markButton(_ title: String, value: Int?, set: @escaping () -> Void) -> some View {
        let on = value != nil
        return Button(action: set) {
            VStack(spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(value.map { "bild \($0 + 1)" } ?? "tryck här").font(.system(size: 13)).opacity(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(on ? Theme.accent : Theme.text)
            .background(on ? Theme.accent.opacity(0.12) : Theme.surface, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(on ? Theme.accent : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let value { Button("Gå till bild \(value + 1)") { go(to: value) } }
        }
    }

    @ViewBuilder
    private func bottom(_ video: VideoFrames) -> some View {
        if let firstAir, let landing {
            let marking = FlightMarking(firstAirFrame: firstAir, landingFrame: landing)
            switch Result(catching: { try video.clock.flightTime(marking) }) {
            case let .success(t):
                if let mass = store.history.bodyMassKg {
                    let r = JumpResult(flightTime: t, frameInterval: video.clock.frameInterval, massKg: mass)
                    Button { save(t, marking, video, mass) } label: {
                        HStack {
                            Text("Visa resultat")
                            Spacer()
                            Text("\(Format.cm(r.height)) cm").font(Theme.number(24)).monospacedDigit()
                        }
                        .padding(.horizontal, 24)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    massField
                }
            case let .failure(error):
                hint(Self.text(for: error), color: Theme.warning)
            }
        } else {
            hint("Markera avstamp och landning", color: Theme.secondary)
        }
    }

    private func hint(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Theme.surface, in: .capsule)
    }

    private var massField: some View {
        HStack {
            TextField("Din vikt i kg", text: $massText)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
                .background(Theme.surface, in: .capsule)
            Button("Spara") {
                if let kg = Double(massText.replacingOccurrences(of: ",", with: ".")), kg > 20, kg < 250 {
                    store.setBodyMass(kg)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    static func text(for error: Error) -> String {
        switch error as? MarkingError {
        case .landingNotAfterTakeoff: return "Landningen måste komma efter avstampet."
        case .tooShort: return "För kort tid i luften. Kontrollera markeringarna."
        case .tooLong: return "För lång tid i luften. Är videon omsparad med nedsaktningen inbakad?"
        default: return "Markeringen ligger utanför videon."
        }
    }

    private func visibleRange(_ video: VideoFrames) -> ClosedRange<Int> {
        let count = video.clock.count
        let span = 2 * Self.window
        let lower = min(max(frame - Self.window, 0), max(count - 1 - span, 0))
        return lower...min(lower + span, count - 1)
    }

    private func load() async {
        guard video == nil else { return }
        do {
            video = try await VideoFrames.load(url)
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
        let range = visibleRange(video)
        thumbTask?.cancel()
        thumbTask = Task {
            for k in range where thumbs[k] == nil {
                guard !Task.isCancelled else { return }
                if let t = try? await video.thumbnail(at: k) { thumbs[k] = t }
            }
            // Håll minnet nere: bara bilderna nära den aktuella sparas.
            for k in thumbs.keys where abs(k - i) > 40 { thumbs[k] = nil }
        }
    }

    private func save(_ t: Double, _ marking: FlightMarking, _ video: VideoFrames, _ mass: Double) {
        let attempt = JumpAttempt(recordedAt: video.recordedAt ?? Date(), style: style, massKg: mass, flightTime: t,
                                  frameInterval: video.clock.frameInterval, marking: marking,
                                  videoFileName: url.lastPathComponent)
        store.add(attempt)
        firstAir = nil
        landing = nil
        onSaved(attempt.id)
    }
}

// MARK: - Resultatet

struct ResultView: View {
    let attemptID: UUID
    let onNext: () -> Void
    let onSameVideo: () -> Void
    let onDone: () -> Void

    @Environment(Store.self) private var store

    var body: some View {
        if let attempt = store.history.attempts.first(where: { $0.id == attemptID }) {
            content(attempt)
        } else {
            ContentUnavailableView("Hoppet finns inte längre", systemImage: "questionmark")
        }
    }

    private func content(_ attempt: JumpAttempt) -> some View {
        let r = attempt.result
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: attempt.recordedAt)
        let days = store.days
        let baseline = Analysis.baseline(style: attempt.style, before: day, among: days)
        let left = Analysis.daysUntilBaseline(style: attempt.style, before: day, among: days)
        let todays = days.first { $0.style == attempt.style && $0.day == day }?.attempts ?? [attempt]
        let best = todays.max { $0.flightTime < $1.flightTime }?.id
        let next = TestDay.next(store.history.attempts, on: Date(), calendar: calendar)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(Format.cm(r.height)).font(Theme.number(112)).monospacedDigit()
                        Text("cm").font(.system(size: 24)).foregroundStyle(Theme.secondary)
                    }
                    Text("± \(Format.cm(r.heightUncertainty)) cm · \(Format.ms(r.flightTime)) ms i luften")
                        .font(.system(size: 15)).foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

                if let baseline {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Mot din normala nivå").font(.system(size: 15))
                            Spacer()
                            Text("\(Format.percent(baseline.change(of: r.height))) %")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(baseline.change(of: r.height) < Readiness.loweredBelow ? Theme.warning : Theme.accent)
                        }
                        BandBar(value: r.height, baseline: baseline)
                    }
                    .card()
                } else {
                    Text(left == 1 ? "Normalnivån finns efter en testdag till" : "Normalnivån finns efter \(left) testdagar till")
                        .font(.system(size: 15)).foregroundStyle(Theme.secondary)
                        .card()
                }

                HStack(spacing: 10) {
                    tile("Impuls", Format.whole(r.impulse), "N·s")
                    tile("Effekt", Format.whole(r.peakPower), "W")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dagens \(attempt.style.name)").overline()
                    HStack(spacing: 10) {
                        ForEach(todays) { a in
                            Text(Format.cm(a.result.height))
                                .font(Theme.number(22, weight: a.id == best ? .bold : .semibold))
                                .monospacedDigit()
                                .foregroundStyle(a.id == best ? Theme.text : Theme.secondary)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(a.id == best ? Theme.accent : Theme.line, lineWidth: a.id == best ? 2 : 1))
                        }
                    }
                }

                VStack(spacing: 10) {
                    Button(next.map { "Nästa: \($0.style.name), hopp \($0.number)" } ?? "Ett hopp till", action: onNext)
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Ett hopp till i samma video", action: onSameVideo)
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Klar för idag", action: onDone)
                        .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Theme.ground)
        .navigationTitle(attempt.style.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(Theme.number(30)).monospacedDigit()
                Text(unit).font(.system(size: 15)).foregroundStyle(Theme.secondary)
            }
        }
        .card(padding: 16, radius: 18)
    }
}

/// Ett hopp mot normalnivån: bandet är dagsbästa de senaste dagarna, punkten är hoppet. METOD M14
struct BandBar: View {
    let value: Double
    let baseline: Baseline

    var body: some View {
        GeometryReader { geo in
            let lo = min(baseline.low, value), hi = max(baseline.high, value)
            let pad = max((hi - lo) * 0.25, 0.01)
            let x = { (v: Double) in CGFloat((v - (lo - pad)) / ((hi + pad) - (lo - pad))) * geo.size.width }
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line).frame(height: 6)
                Capsule().fill(Theme.accent.opacity(0.22))
                    .frame(width: max(x(baseline.high) - x(baseline.low), 14), height: 14)
                    .offset(x: x(baseline.low))
                Circle().fill(Theme.accent).frame(width: 16, height: 16)
                    .offset(x: x(value) - 8)
            }
            .frame(height: 16)
        }
        .frame(height: 16)
        .accessibilityElement()
        .accessibilityLabel("Normal nivå \(Format.cm(baseline.low)) till \(Format.cm(baseline.high)) cm, hoppet \(Format.cm(value)) cm")
    }
}
