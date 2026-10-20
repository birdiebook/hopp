import SwiftUI
import Jump

/// Tre flikar (BESLUT B13): Idag, Utveckling, Jag.
struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Idag", systemImage: "arrow.up.to.line") }
            DevelopmentView()
                .tabItem { Label("Utveckling", systemImage: "chart.line.uptrend.xyaxis") }
            ProfileView()
                .tabItem { Label("Jag", systemImage: "person") }
        }
        .tint(Theme.accent)
    }
}

struct TodayView: View {
    @Environment(Store.self) private var store
    @State private var testing = false

    var body: some View {
        let days = store.days
        let now = Date()
        let calendar = Calendar.current
        let steps = TestDay.progress(store.history.attempts, on: now, calendar: calendar)
        let next = TestDay.next(store.history.attempts, on: now, calendar: calendar)
        let todays = days.first { $0.style == .handsOnHips && calendar.isDate($0.day, inSameDayAs: now) }

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Idag").font(.system(size: 32, weight: .bold))
                        Spacer()
                        Text(Format.day(now)).font(.system(size: 14)).foregroundStyle(Theme.secondary)
                    }
                    .padding(.top, 8)

                    if let problem = store.problem {
                        Text(problem).font(.callout).foregroundStyle(Theme.warning)
                    }

                    ReadinessCard(day: todays, days: days)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Testdagen").font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Text("\(steps.map(\.done).reduce(0, +)) av \(steps.count * TestDay.perStyle)")
                                .font(.system(size: 14)).foregroundStyle(Theme.secondary)
                        }
                        ForEach(steps, id: \.style) { step in
                            HStack {
                                Text(step.style.name).font(.system(size: 15))
                                Spacer()
                                StepDots(done: step.done, current: next?.style == step.style)
                            }
                            .frame(minHeight: 28)
                        }
                    }
                    .card()

                    Button { testing = true } label: {
                        Label(next.map { "\($0.number == 1 ? "Starta" : "Fortsätt"): \($0.style.name), hopp \($0.number)" }
                                ?? "Ett hopp till", systemImage: "arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if let latest = store.history.attempts.max(by: { $0.recordedAt < $1.recordedAt }) {
                        LatestCard(attempt: latest)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.ground)
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $testing) {
            TestFlow(startStyle: next?.style ?? .handsOnHips)
        }
    }
}

/// Dagsformen som en ring (METOD M6).
struct ReadinessCard: View {
    let day: JumpDay?
    let days: [JumpDay]

    var body: some View {
        let readiness = day.map { Analysis.readiness(of: $0, among: days) }
        let left = Analysis.daysUntilBaseline(style: .handsOnHips, before: Calendar.current.startOfDay(for: Date()), among: days)
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Theme.line, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: fill(readiness))
                    .stroke(color(readiness), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(centre(readiness))
                    .font(Theme.number(28))
                    .monospacedDigit()
            }
            .frame(width: 100, height: 100)
            .accessibilityElement()
            .accessibilityLabel(label(readiness, left: left))

            VStack(alignment: .leading, spacing: 6) {
                Text("Dagsform").overline()
                Text(title(readiness, left: left)).font(.system(size: 22, weight: .semibold))
                Text(subtitle(readiness, left: left)).font(.system(size: 14)).foregroundStyle(Theme.secondary)
            }
        }
        .card(padding: 20)
    }

    private func fill(_ r: Readiness?) -> CGFloat {
        switch r {
        case let .normal(c), let .lowered(c): return CGFloat(min(1, max(0.08, 0.75 + c * 2.5)))
        default: return 0
        }
    }

    private func color(_ r: Readiness?) -> Color {
        if case .lowered = r { return Theme.warning }
        return Theme.accent
    }

    private func centre(_ r: Readiness?) -> String {
        switch r {
        case let .normal(c), let .lowered(c): return "\(Format.percent(c)) %"
        default: return "–"
        }
    }

    private func title(_ r: Readiness?, left: Int) -> String {
        switch r {
        case .normal: return "Redo"
        case .lowered: return "Kör lättare"
        case .noBaseline: return "Bygger normalnivån"
        case nil: return left > 0 ? "Bygger normalnivån" : "Hoppa för att se"
        }
    }

    private func subtitle(_ r: Readiness?, left: Int) -> String {
        switch r {
        case .normal, .lowered: return "mot dina \(Readiness.daysUsed) senaste dagar"
        default: return left > 0 ? "\(left) testdagar kvar" : "tre CMJ räcker"
        }
    }

    private func label(_ r: Readiness?, left: Int) -> String {
        "Dagsform: " + title(r, left: left) + ", " + centre(r)
    }
}

struct StepDots: View {
    let done: Int
    let current: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<TestDay.perStyle, id: \.self) { i in
                if i < done {
                    Circle().fill(Theme.accent).frame(width: 12, height: 12)
                } else {
                    Circle().stroke(current && i == done ? Theme.accent : Color(hex: 0x3A414B), lineWidth: 2)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(done) av \(TestDay.perStyle) klara")
    }
}

struct LatestCard: View {
    let attempt: JumpAttempt

    var body: some View {
        let r = attempt.result
        VStack(alignment: .leading, spacing: 10) {
            Text("Senaste hopp · \(attempt.style.name)").overline()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Format.cm(r.height)).font(Theme.number(52)).monospacedDigit()
                Text("cm").font(.system(size: 18)).foregroundStyle(Theme.secondary)
            }
            HStack(spacing: 20) {
                Text("Impuls ").foregroundStyle(Theme.secondary) + Text("\(Format.whole(r.impulse)) N·s").bold()
                Text("Effekt ").foregroundStyle(Theme.secondary) + Text("\(Format.whole(r.peakPower)) W").bold()
            }
            .font(.system(size: 14))
            .monospacedDigit()
        }
        .card()
    }
}
