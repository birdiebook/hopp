import XCTest
@testable import Jump

final class FrameClockTests: XCTestCase {
    func test168BilderVid240ÄrEttHoppPå60cm() throws {
        let klocka = FrameClock(frameRate: 240, count: 600)
        let t = try klocka.flightTime(FlightMarking(firstAirFrame: 100, landingFrame: 268))
        XCTAssertEqual(t, 0.70, accuracy: 1e-9)
        XCTAssertEqual(JumpMath.height(flightTime: t), 0.6008625, accuracy: 1e-9)
    }

    func test42BilderVid60GerSammaTid() throws {
        let klocka = FrameClock(frameRate: 60, count: 300)
        XCTAssertEqual(try klocka.flightTime(FlightMarking(firstAirFrame: 10, landingFrame: 52)), 0.70, accuracy: 1e-9)
        XCTAssertEqual(klocka.frameRate, 60)
    }

    func testOjämnTaktLäsesUrBildtidernaInteUrFrekvensen() throws {
        // Bilderna 0–9 med 1/240 s, sedan ett glapp där två bilder fattas.
        var tider = (0..<10).map { Double($0) / 240 }
        tider += (12..<200).map { Double($0) / 240 }
        let klocka = FrameClock(times: tider.shuffled())
        XCTAssertEqual(klocka.frameRate, 240)
        // Index 5 är bild 5; index 100 är bild 102, eftersom två fattas.
        let t = try klocka.flightTime(FlightMarking(firstAirFrame: 5, landingFrame: 100))
        XCTAssertEqual(t, 97.0 / 240, accuracy: 1e-12)
    }

    func testFelMarkeringar() {
        let klocka = FrameClock(frameRate: 240, count: 400)
        XCTAssertThrowsError(try klocka.flightTime(FlightMarking(firstAirFrame: 10, landingFrame: 400))) {
            XCTAssertEqual($0 as? MarkingError, .outOfRange)
        }
        XCTAssertThrowsError(try klocka.flightTime(FlightMarking(firstAirFrame: 50, landingFrame: 50))) {
            XCTAssertEqual($0 as? MarkingError, .landingNotAfterTakeoff)
        }
        XCTAssertThrowsError(try klocka.flightTime(FlightMarking(firstAirFrame: 50, landingFrame: 60))) {
            XCTAssertEqual($0 as? MarkingError, .tooShort)
        }
    }

    func testOmsparadSlowMotionFällsSomFörLång() {
        // Ett hopp på 0,7 s i en slow motion som sparats om till 30 bilder/s med
        // nedsaktningen inbakad: 8 × 0,7 s = 5,6 s = 168 bilder vid 30 bilder/s.
        let klocka = FrameClock(frameRate: 30, count: 400)
        XCTAssertThrowsError(try klocka.flightTime(FlightMarking(firstAirFrame: 20, landingFrame: 188))) {
            XCTAssertEqual($0 as? MarkingError, .tooLong)
        }
    }

    func testTomOchEnsamKlocka() {
        XCTAssertEqual(FrameClock(times: []).frameRate, 0)
        XCTAssertEqual(FrameClock(times: [0.5]).frameInterval, 0)
    }
}
