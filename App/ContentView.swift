import Charts
import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import Jump

struct ContentView: View {
    @Environment(Store.self) private var store

    @State private var recording = false
    @State private var picked: PhotosPickerItem?
    @State private var reviewing: PickedMovie?
    @State private var importing = false
    @State private var importProblem: String?
    @State private var settings = false
    @State private var style: JumpStyle = .handsOnHips

    var body: some View {
        NavigationStack {
            List {
                if let problem = store.problem ?? importProblem {
                    Text(problem).foregroundStyle(.orange)
                }
                if store.history.bodyMassKg == nil {
                    Button("Ange din vikt") { settings = true }
                }
                let days = store.days
                let mine = days.filter { $0.style == style }
                Section {
                    Picker("Sort", selection: $style) {
                        Text("Händer på höfterna").tag(JumpStyle.handsOnHips)
                        Text("Armsving").tag(JumpStyle.armSwing)
                    }
                    .pickerStyle(.segmented)
                    if let latest = mine.last {
                        LatestDay(day: latest, readiness: Analysis.readiness(of: latest, among: days))
                    }
                    if mine.count > 1 {
                        ProgressChart(days: mine)
                    }
                }
                if !mine.isEmpty {
                    Section {
                        ForEach(mine.reversed(), id: \.day) { day in
                            NavigationLink { DayView(day: day) } label: { DayRow(day: day) }
                        }
                    }
                }
            }
            .overlay {
                if store.history.attempts.isEmpty {
                    ContentUnavailableView("Inga hopp än", systemImage: "figure.jumprope")
                }
            }
            .navigationTitle("Hopp")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { settings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button { recording = true } label: {
                        Label("Spela in", systemImage: "video.fill").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    // .current: originalfilen, så att en slow motion inte räknas om till 30 bilder/s. METOD M5
                    PhotosPicker(selection: $picked, matching: .videos, preferredItemEncoding: .current) {
                        Label(importing ? "Hämtar…" : "Välj video", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.bordered)
                    .disabled(importing)
                }
                .padding()
                .background(.bar)
            }
        }
        .fullScreenCover(isPresented: $recording) { RecordFlow() }
        .fullScreenCover(item: $reviewing) { ReviewView(url: $0.url) }
        .sheet(isPresented: $settings) { SettingsView() }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            importing = true
            importProblem = nil
            Task {
                do {
                    reviewing = try await item.loadTransferable(type: PickedMovie.self)
                } catch {
                    importProblem = "Videon gick inte att hämta."
                }
                importing = false
                picked = nil
            }
        }
    }
}

/// En video vald ur Bilder, kopierad till appens videomapp.
struct PickedMovie: Transferable, Identifiable {
    let url: URL
    var id: URL { url }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let dest = Store.videos.appending(path: "\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return PickedMovie(url: dest)
        }
    }
}

/// Senaste dagen: bästa hoppet och dagsformen.
struct LatestDay: View {
    let day: JumpDay
    let readiness: Readiness

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.day.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
            ResultSummary(result: day.best.result)
            switch readiness {
            case .noBaseline:
                EmptyView()
            case let .normal(change):
                Label("Dagsform \(Format.percent(change)) %", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            case let .lowered(change):
                Label("Dagsform \(Format.percent(change)) %: kör lättare", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
    }
}

/// Bästa hoppet per dag över tid.
struct ProgressChart: View {
    let days: [JumpDay]
    @State private var measure = Measure.height

    enum Measure: String, CaseIterable {
        case height = "Höjd, cm"
        case impulse = "Impuls, N·s"
        case power = "Effekt, W"

        func value(_ r: JumpResult) -> Double {
            switch self {
            case .height: return r.height * 100
            case .impulse: return r.impulse
            case .power: return r.peakPower
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Picker("Mått", selection: $measure) {
                ForEach(Measure.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Chart(days, id: \.day) { day in
                LineMark(x: .value("Dag", day.day, unit: .day), y: .value(measure.rawValue, measure.value(day.best.result)))
                PointMark(x: .value("Dag", day.day, unit: .day), y: .value(measure.rawValue, measure.value(day.best.result)))
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
        }
    }
}

struct DayRow: View {
    let day: JumpDay

    var body: some View {
        HStack {
            Text(day.day.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Text("\(day.attempts.count) hopp").foregroundStyle(.secondary)
            Text("\(Format.cm(day.best.result.height)) cm").bold().monospacedDigit()
        }
    }
}

struct DayView: View {
    let day: JumpDay
    @Environment(Store.self) private var store

    var body: some View {
        List {
            ForEach(day.attempts) { attempt in
                VStack(alignment: .leading, spacing: 4) {
                    Text(attempt.recordedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                    ResultSummary(result: attempt.result)
                }
            }
            .onDelete { offsets in
                for i in offsets { store.delete(day.attempts[i]) }
            }
        }
        .navigationTitle(day.day.formatted(date: .abbreviated, time: .omitted))
    }
}

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var massText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Vikt") {
                    TextField("kg", text: $massText).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Inställningar")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        if let kg = Double(massText.replacingOccurrences(of: ",", with: ".")), kg > 20, kg < 250 {
                            store.setBodyMass(kg)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let kg = store.history.bodyMassKg { massText = Format.whole(kg) }
            }
        }
    }
}
