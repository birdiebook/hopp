import XCTest
@testable import Jump

/// Påhittade hopp (CLAUDE.md, Dataregeln).
final class ProgressTests: XCTestCase {
    private var kalender: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return c
    }()

    private func tid(_ s: String) -> Date {
        ISO8601DateFormatter().date(from: s)!
    }

    private func hopp(_ när: String, höjd: Double, sort: JumpStyle = .handsOnHips) -> JumpAttempt {
        JumpAttempt(recordedAt: tid(när), style: sort, massKg: 80,
                    flightTime: JumpMath.flightTime(height: höjd), frameInterval: 1.0 / 240,
                    marking: FlightMarking(firstAirFrame: 1, landingFrame: 2))
    }

    func testNormalnivånÄrDagsbästaUnderDeSenasteDagarna() throws {
        // Dagsbästa 0,40 · 0,44 · 0,42; den 4:e dagens hopp räknas inte in i sin egen normalnivå.
        let dagar = Analysis.days([hopp("2026-01-01T18:00:00Z", höjd: 0.38), hopp("2026-01-01T18:01:00Z", höjd: 0.40),
                                   hopp("2026-01-02T18:00:00Z", höjd: 0.44),
                                   hopp("2026-01-03T18:00:00Z", höjd: 0.42),
                                   hopp("2026-01-04T18:00:00Z", höjd: 0.50)], calendar: kalender)
        let n = try XCTUnwrap(Analysis.baseline(style: .handsOnHips, before: dagar[3].day, among: dagar))
        XCTAssertEqual(n.median, 0.42, accuracy: 1e-12)
        XCTAssertEqual(n.low, 0.40, accuracy: 1e-12)
        XCTAssertEqual(n.high, 0.44, accuracy: 1e-12)
        XCTAssertEqual(n.days, 3)
        XCTAssertEqual(n.change(of: 0.4326), 0.03, accuracy: 1e-9)
    }

    func testIngenNormalnivåFörränTreDagar() {
        let dagar = Analysis.days([hopp("2026-01-01T18:00:00Z", höjd: 0.40),
                                   hopp("2026-01-02T18:00:00Z", höjd: 0.41, sort: .armSwing),
                                   hopp("2026-01-03T18:00:00Z", höjd: 0.42)], calendar: kalender)
        let idag = kalender.startOfDay(for: tid("2026-01-04T18:00:00Z"))
        XCTAssertNil(Analysis.baseline(style: .handsOnHips, before: idag, among: dagar))
        // Två dagar med standardhoppet; armsvingen räknas inte.
        XCTAssertEqual(Analysis.daysUntilBaseline(style: .handsOnHips, before: idag, among: dagar), 1)
        XCTAssertEqual(Analysis.daysUntilBaseline(style: .armSwing, before: idag, among: dagar), 2)
    }

    func testTestdagenRäknarDagensHoppAvRättSort() {
        let lista = [hopp("2026-01-04T17:00:00Z", höjd: 0.4), hopp("2026-01-04T17:02:00Z", höjd: 0.4),
                     hopp("2026-01-04T17:03:00Z", höjd: 0.4, sort: .armSwing),
                     hopp("2026-01-03T17:00:00Z", höjd: 0.4)]
        let dag = tid("2026-01-04T12:00:00Z")
        XCTAssertEqual(TestDay.progress(lista, on: dag, calendar: kalender),
                       [TestDay.Step(style: .handsOnHips, done: 2)])
        let nästa = TestDay.next(lista, on: dag, calendar: kalender)
        XCTAssertEqual(nästa?.style, .handsOnHips)
        XCTAssertEqual(nästa?.number, 3)
    }

    func testTestdagenÄrKlarEfterTreOchRäknarInteFler() {
        let lista = (0..<5).map { hopp("2026-01-04T17:0\($0):00Z", höjd: 0.4) }
        let dag = tid("2026-01-04T12:00:00Z")
        XCTAssertEqual(TestDay.progress(lista, on: dag, calendar: kalender).first?.done, 3)
        XCTAssertNil(TestDay.next(lista, on: dag, calendar: kalender))
    }

    func testÄldreFilUtanLängdOchSpelhandGårAttLäsa() throws {
        let json = #"{"attempts":[],"bodyMassKg":75,"version":1}"#
        let h = try History.decode(Data(json.utf8))
        XCTAssertNil(h.bodyHeightCm)
        XCTAssertNil(h.playsRightHanded)
        let ny = History(bodyMassKg: 75, bodyHeightCm: 180, playsRightHanded: false)
        XCTAssertEqual(try History.decode(ny.encoded()), ny)
    }
}
