import Charts
import SwiftUI
import Jump

/// Ett mått i taget över tid, med bandet för den normala nivån (BESLUT B13, METOD M14).
struct DevelopmentView: View {
    @Environment(Store.self) private var store
    @State private var measure = Measure.height
    @State private var style: JumpStyle = .handsOnHips

    enum Measure: String, CaseIterable, Identifiable {
        case height = "Höjd"
        case impulse = "Impuls"
        case power = "Effekt"

        var id: String { rawValue }

        var unit: String {
            switch self {
            case .height: return "cm"
            case .impulse: return "N·s"
            case .power: return "W"
            }
        }

        func value(_ r: JumpResult) -> Double {
            switch self {
            case .height: return r.height * 100
            case .impulse: return r.impulse
            case .power: return r.peakPower
            }
        }

        func text(_ v: Double) -> String {
            self == .height ? v.formatted(.number.precision(.fractionLength(1))) : Format.whole(v)
        }
    }

    struct Point {
        let day: Date
        let value: Double
    }

    var body: some View {
        let days = store.days.filter { $0.style == style }
        let values = days.map { Point(day: $0.day, value: measure.value($0.best.result)) }
        let recent = values.suffix(Readiness.daysUsed).map { $0.value }
        let band: (Double, Double)? = recent.count >= Readiness.daysNeeded ? (recent.min()!, recent.max()!) : nil

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Utveckling").font(.system(size: 32, weight: .bold))
                        Spacer()
                        Menu {
                            Picker("Sort", selection: $style) {
                                ForEach(JumpStyle.allCases, id: \.self) { Text($0.name).tag($0) }
                            }
                        } label: {
                            Label(style.name, systemImage: "chevron.down")
                                .labelStyle(.titleAndIcon)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.top, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Measure.allCases) { m in
                                Button { measure = m } label: {
                                    Text(m.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(m == measure ? Theme.onAccent : Theme.text)
                                        .padding(.horizontal, 16)
                                        .frame(minHeight: 40)
                                        .background(m == measure ? Theme.accent : Theme.surface, in: .capsule)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let last = values.last, let first = values.first {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(measure.text(last.value)).font(Theme.number(56)).monospacedDigit()
                                Text(measure.unit).font(.system(size: 17)).foregroundStyle(Theme.secondary)
                                Spacer()
                                if values.count > 1 {
                                    let d = last.value - first.value
                                    Text("\(d >= 0 ? "+" : "−")\(measure.text(abs(d))) sedan start")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            Chart {
                                if let band {
                                    RectangleMark(yStart: .value("Låg", band.0), yEnd: .value("Hög", band.1))
                                        .foregroundStyle(Theme.accent.opacity(0.12))
                                }
                                ForEach(values, id: \.day) { v in
                                    LineMark(x: .value("Dag", v.day, unit: .day), y: .value(measure.rawValue, v.value))
                                        .foregroundStyle(Theme.accent)
                                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    PointMark(x: .value("Dag", v.day, unit: .day), y: .value(measure.rawValue, v.value))
                                        .foregroundStyle(Theme.accent)
                                        .symbolSize(v.day == last.day ? 90 : 30)
                                }
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                        .foregroundStyle(Theme.secondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                                    AxisGridLine().foregroundStyle(Theme.line)
                                    AxisValueLabel().foregroundStyle(Theme.secondary)
                                }
                            }
                            .frame(height: 200)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Testdagar").overline().padding(.bottom, 6)
                            ForEach(days.reversed(), id: \.day) { day in
                                NavigationLink { DayView(day: day) } label: {
                                    HStack {
                                        Text(Format.day(day.day)).font(.system(size: 15)).foregroundStyle(Theme.text)
                                        Spacer()
                                        Text("\(measure.text(measure.value(day.best.result))) \(measure.unit)")
                                            .font(Theme.number(22, weight: .semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(Theme.text)
                                        Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                                    }
                                    .frame(minHeight: 48)
                                }
                                Divider().overlay(Theme.raised)
                            }
                        }
                    } else {
                        ContentUnavailableView("Inga hopp än", systemImage: "chart.line.uptrend.xyaxis")
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.ground)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// En dags hopp av en sort, med möjlighet att ta bort ett.
struct DayView: View {
    let day: JumpDay
    @Environment(Store.self) private var store

    var body: some View {
        let attempts = store.history.attempts
            .filter { a in day.attempts.contains { $0.id == a.id } }
            .sorted { $0.recordedAt < $1.recordedAt }
        List {
            ForEach(attempts) { a in
                let r = a.result
                HStack(alignment: .firstTextBaseline) {
                    Text(a.recordedAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 14)).foregroundStyle(Theme.secondary)
                    Spacer()
                    Text("\(Format.cm(r.height)) cm").font(Theme.number(24)).monospacedDigit()
                    Text("\(Format.whole(r.impulse)) N·s").font(.system(size: 14)).foregroundStyle(Theme.secondary)
                        .monospacedDigit()
                }
                .listRowBackground(Theme.surface)
            }
            .onDelete { offsets in
                for i in offsets { store.delete(attempts[i]) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.ground)
        .navigationTitle(Format.day(day.day))
    }
}

/// Inställningarna (BESLUT B13): vikt, längd och spelhand.
struct ProfileView: View {
    @Environment(Store.self) private var store
    @State private var massText = ""
    @State private var heightText = ""
    @State private var right = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    row("Vikt", text: $massText, unit: "kg")
                    row("Längd", text: $heightText, unit: "cm")
                }
                .listRowBackground(Theme.surface)

                Section {
                    Picker("Spelar", selection: $right) {
                        Text("Höger").tag(true)
                        Text("Vänster").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Spelar")
                } footer: {
                    Text("Golfsidan i kastet: \(right ? "mot vänster" : "mot höger")")
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.ground)
            .navigationTitle("Jag")
            .onAppear {
                if let kg = store.history.bodyMassKg { massText = kg.formatted(.number.precision(.fractionLength(0...1))) }
                if let cm = store.history.bodyHeightCm { heightText = Format.whole(cm) }
                right = store.history.playsRightHanded ?? true
            }
            .onChange(of: massText) { _, t in
                if let kg = Self.number(t), kg > 20, kg < 250 { store.setBodyMass(kg) }
            }
            .onChange(of: heightText) { _, t in
                if let cm = Self.number(t), cm > 100, cm < 250 { store.setBodyHeight(cm) }
            }
            .onChange(of: right) { _, r in store.setPlaysRightHanded(r) }
        }
    }

    private func row(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("–", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.number(24))
                .frame(width: 90)
            Text(unit).foregroundStyle(Theme.secondary)
        }
        .frame(minHeight: 44)
    }

    static func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }
}
