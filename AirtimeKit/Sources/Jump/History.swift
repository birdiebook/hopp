import Foundation

/// Hur hoppet gjordes. Bara hopp av samma sort jämförs med varandra.
public enum JumpStyle: String, Codable, CaseIterable, Sendable {
    /// CMJ med händerna på höfterna, standardmåttet. METOD M1
    case handsOnHips
    /// CMJ med armsving, ett eget mått.
    case armSwing
}

/// Ett sparat hopp. Resultatet räknas om ur tiden i luften och vikten, så att
/// en rättad formel gäller även gamla hopp.
public struct JumpAttempt: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var recordedAt: Date
    public var style: JumpStyle
    public var massKg: Double
    public var flightTime: Double
    public var frameInterval: Double
    public var marking: FlightMarking
    /// Videons filnamn i appens mapp, eller nil när videon är borttagen.
    public var videoFileName: String?

    public init(id: UUID = UUID(), recordedAt: Date, style: JumpStyle, massKg: Double, flightTime: Double,
                frameInterval: Double, marking: FlightMarking, videoFileName: String? = nil) {
        self.id = id
        self.recordedAt = recordedAt
        self.style = style
        self.massKg = massKg
        self.flightTime = flightTime
        self.frameInterval = frameInterval
        self.marking = marking
        self.videoFileName = videoFileName
    }

    public var result: JumpResult {
        JumpResult(flightTime: flightTime, frameInterval: frameInterval, massKg: massKg)
    }
}

/// Allt appen sparar. Ligger som JSON i appens Application Support.
public struct History: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    /// Vikten som föreslås för nästa hopp, eller nil innan den angetts.
    public var bodyMassKg: Double?
    public var attempts: [JumpAttempt]

    public init(bodyMassKg: Double? = nil, attempts: [JumpAttempt] = []) {
        version = Self.currentVersion
        self.bodyMassKg = bodyMassKg
        self.attempts = attempts
    }

    public static func decode(_ data: Data) throws -> History {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(History.self, from: data)
    }

    public func encoded() throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try e.encode(self)
    }
}

/// En dags hopp av en sort.
public struct JumpDay: Equatable, Sendable {
    public let day: Date
    public let style: JumpStyle
    public let attempts: [JumpAttempt]

    /// Dagens bästa hopp: det som visar utvecklingen.
    public var best: JumpAttempt {
        attempts.max { $0.flightTime < $1.flightTime }!
    }

    /// Snitthöjden: det som visar dagsformen. METOD M6
    public var meanHeight: Double {
        attempts.map { $0.result.height }.reduce(0, +) / Double(attempts.count)
    }
}

/// Dagsformen mot de senaste dagarna. METOD M6
public enum Readiness: Equatable, Sendable {
    /// Färre än `Readiness.daysNeeded` tidigare dagar att jämföra med.
    case noBaseline
    /// Snitthöjden mot baslinjen, som andel (−0,03 = 3 % lägre).
    case normal(change: Double)
    case lowered(change: Double)

    public static let daysNeeded = 3
    public static let daysUsed = 5
    public static let loweredBelow = -0.05
}

public enum Analysis {
    /// Hoppen per dag och sort, äldst först.
    public static func days(_ attempts: [JumpAttempt], calendar: Calendar) -> [JumpDay] {
        let groups = Dictionary(grouping: attempts) { a in
            DayKey(day: calendar.startOfDay(for: a.recordedAt), style: a.style)
        }
        return groups
            .map { key, list in
                JumpDay(day: key.day, style: key.style, attempts: list.sorted { $0.recordedAt < $1.recordedAt })
            }
            .sorted { ($0.day, $0.style.rawValue) < ($1.day, $1.style.rawValue) }
    }

    /// Dagens snitt mot medianen av upp till fem tidigare dagar av samma sort. METOD M6
    public static func readiness(of day: JumpDay, among days: [JumpDay]) -> Readiness {
        let earlier = days
            .filter { $0.style == day.style && $0.day < day.day }
            .suffix(Readiness.daysUsed)
        guard earlier.count >= Readiness.daysNeeded else { return .noBaseline }
        let baseline = median(earlier.map(\.meanHeight))
        let change = day.meanHeight / baseline - 1
        return change <= Readiness.loweredBelow ? .lowered(change: change) : .normal(change: change)
    }

    static func median(_ values: [Double]) -> Double {
        let s = values.sorted()
        let mid = s.count / 2
        return s.count % 2 == 1 ? s[mid] : (s[mid - 1] + s[mid]) / 2
    }

    private struct DayKey: Hashable {
        let day: Date
        let style: JumpStyle
    }
}
