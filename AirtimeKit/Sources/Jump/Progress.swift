import Foundation

/// Den normala nivån för en sort: bästa höjden de senaste dagarna. METOD M14
public struct Baseline: Equatable, Sendable {
    public let median: Double
    public let low: Double
    public let high: Double
    public let days: Int

    /// Ett hopps höjd mot medianen, som andel (0,03 = 3 % högre).
    public func change(of height: Double) -> Double {
        height / median - 1
    }
}

extension Analysis {
    /// Normalnivån före `day`: dagsbästa för samma sort under upp till fem tidigare dagar, minst tre. METOD M14
    public static func baseline(style: JumpStyle, before day: Date, among days: [JumpDay]) -> Baseline? {
        let earlier = days.filter { $0.style == style && $0.day < day }.suffix(Readiness.daysUsed)
        guard earlier.count >= Readiness.daysNeeded else { return nil }
        let best = earlier.map { $0.best.result.height }
        return Baseline(median: median(best), low: best.min()!, high: best.max()!, days: earlier.count)
    }

    /// Hur många testdagar till som behövs innan normalnivån finns.
    public static func daysUntilBaseline(style: JumpStyle, before day: Date, among days: [JumpDay]) -> Int {
        let earlier = days.filter { $0.style == style && $0.day < day }.count
        return max(0, Readiness.daysNeeded - earlier)
    }
}

/// Testdagen: sorterna i ordning och tre hopp av varje (PLAN.md H6 lägger till fler sorter).
public enum TestDay {
    public static let order: [JumpStyle] = [.handsOnHips]
    public static let perStyle = 3

    public struct Step: Equatable, Sendable {
        public let style: JumpStyle
        public let done: Int
    }

    /// Hur långt dagen har kommit, sort för sort.
    public static func progress(_ attempts: [JumpAttempt], on day: Date, calendar: Calendar) -> [Step] {
        let today = attempts.filter { calendar.isDate($0.recordedAt, inSameDayAs: day) }
        return order.map { style in
            Step(style: style, done: min(perStyle, today.filter { $0.style == style }.count))
        }
    }

    /// Nästa hopp: sorten och vilket i ordningen (1-baserat), eller nil när dagen är klar.
    public static func next(_ attempts: [JumpAttempt], on day: Date, calendar: Calendar) -> (style: JumpStyle, number: Int)? {
        progress(attempts, on: day, calendar: calendar)
            .first { $0.done < perStyle }
            .map { ($0.style, $0.done + 1) }
    }
}
