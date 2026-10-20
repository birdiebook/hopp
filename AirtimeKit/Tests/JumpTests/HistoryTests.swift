import XCTest
@testable import Jump

/// Påhittade hopp. Inga riktiga mätningar i testerna (CLAUDE.md, Dataregeln).
final class HistoryTests: XCTestCase {
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

    func testSparaOchLäsTillbaka() throws {
        let h = History(bodyMassKg: 80, attempts: [hopp("2026-01-05T18:00:00Z", höjd: 0.4),
                                                    hopp("2026-01-06T18:00:00Z", höjd: 0.42, sort: .armSwing)])
        let tillbaka = try History.decode(h.encoded())
        XCTAssertEqual(tillbaka, h)
        XCTAssertEqual(tillbaka.version, 1)
        XCTAssertEqual(tillbaka.attempts[1].style, .armSwing)
    }

    func testFilformatetÄrStabilt() throws {
        // Fryser nycklarna: byts ett namn i koden ska gamla filer fortfarande gå att läsa.
        let json = """
        {"attempts":[{"flightTime":0.5,"frameInterval":0.004166,"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF",
        "marking":{"firstAirFrame":10,"landingFrame":130},"massKg":75,"recordedAt":"2026-02-01T10:00:00Z",
        "style":"handsOnHips","videoFileName":"a.mov"}],"bodyMassKg":75,"version":1}
        """
        let h = try History.decode(Data(json.utf8))
        XCTAssertEqual(h.attempts.count, 1)
        XCTAssertEqual(h.attempts[0].marking.landingFrame, 130)
        XCTAssertEqual(h.attempts[0].result.height, 9.81 * 0.25 / 8, accuracy: 1e-12)
    }

    func testDagarnaFöljerSvenskTid() {
        // 23:30 UTC den 5 januari är 00:30 den 6:e i Stockholm.
        let dagar = Analysis.days([hopp("2026-01-05T22:30:00Z", höjd: 0.40),
                                   hopp("2026-01-05T23:30:00Z", höjd: 0.41),
                                   hopp("2026-01-06T17:00:00Z", höjd: 0.43)], calendar: kalender)
        XCTAssertEqual(dagar.count, 2)
        XCTAssertEqual(dagar[0].attempts.count, 1)
        XCTAssertEqual(dagar[1].attempts.count, 2)
        XCTAssertEqual(dagar[1].best.result.height, 0.43, accuracy: 1e-12)
        XCTAssertEqual(dagar[1].meanHeight, 0.42, accuracy: 1e-12)
    }

    func testSorternaHållsIsär() {
        let dagar = Analysis.days([hopp("2026-01-05T18:00:00Z", höjd: 0.40),
                                   hopp("2026-01-05T18:05:00Z", höjd: 0.46, sort: .armSwing)], calendar: kalender)
        XCTAssertEqual(dagar.count, 2)
        XCTAssertEqual(Set(dagar.map(\.style)), [.handsOnHips, .armSwing])
    }

    func testDagsformenKräverTreTidigareDagar() {
        let dagar = Analysis.days([hopp("2026-01-01T18:00:00Z", höjd: 0.40),
                                   hopp("2026-01-02T18:00:00Z", höjd: 0.40),
                                   hopp("2026-01-03T18:00:00Z", höjd: 0.30)], calendar: kalender)
        XCTAssertEqual(Analysis.readiness(of: dagar[2], among: dagar), .noBaseline)
    }

    func testSänktDagsformMotMedianenAvDeSenasteFem() {
        // Sex tidigare dagar: den äldsta (0,60) ska inte räknas, och medianen av de fem är 0,40.
        let höjder = [0.60, 0.38, 0.40, 0.41, 0.40, 0.39]
        var lista = höjder.enumerated().map { i, h in hopp("2026-01-0\(i + 1)T18:00:00Z", höjd: h) }
        lista.append(hopp("2026-01-07T18:00:00Z", höjd: 0.37))
        lista.append(hopp("2026-01-07T18:02:00Z", höjd: 0.37))
        let dagar = Analysis.days(lista, calendar: kalender)
        guard case let .lowered(ändring) = Analysis.readiness(of: dagar.last!, among: dagar) else {
            return XCTFail("0,37 mot 0,40 är 7,5 % lägre och ska flaggas")
        }
        XCTAssertEqual(ändring, 0.37 / 0.40 - 1, accuracy: 1e-12)
    }

    func testNormalDagsformInnanförGränsen() {
        let lista = [0.40, 0.40, 0.40].enumerated().map { i, h in hopp("2026-01-0\(i + 1)T18:00:00Z", höjd: h) }
            + [hopp("2026-01-04T18:00:00Z", höjd: 0.39)]
        let dagar = Analysis.days(lista, calendar: kalender)
        guard case let .normal(ändring) = Analysis.readiness(of: dagar.last!, among: dagar) else {
            return XCTFail("2,5 % lägre ligger inom gränsen")
        }
        XCTAssertEqual(ändring, -0.025, accuracy: 1e-12)
    }
}
