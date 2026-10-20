import XCTest
@testable import Jump

/// Facit räknat för hand (Python) ur formlerna i docs/METOD.md, inte ur koden.
final class JumpMathTests: XCTestCase {
    func testHöjdenUrTidenILuften() {
        XCTAssertEqual(JumpMath.height(flightTime: 0.70), 0.6008625, accuracy: 1e-9)
        XCTAssertEqual(JumpMath.height(flightTime: 0.639), 0.5007036, accuracy: 1e-6)
    }

    func testTidenOchHöjdenÄrVarandrasInvers() {
        XCTAssertEqual(JumpMath.flightTime(height: 0.60), 0.6994974, accuracy: 1e-6)
        for h in [0.05, 0.3, 0.55, 0.9] {
            XCTAssertEqual(JumpMath.height(flightTime: JumpMath.flightTime(height: h)), h, accuracy: 1e-12)
        }
    }

    func testAvstampsfartOchImpuls() {
        XCTAssertEqual(JumpMath.takeoffVelocity(flightTime: 0.70), 3.4335, accuracy: 1e-9)
        XCTAssertEqual(JumpMath.impulse(flightTime: 0.70, massKg: 90), 309.015, accuracy: 1e-9)
        XCTAssertEqual(JumpMath.impulse(flightTime: 0.639, massKg: 90), 282.08655, accuracy: 1e-6)
    }

    func testEffektenEnligtSayers() {
        // 60,7 · 60,08625 cm + 45,3 · 90 kg − 2055
        XCTAssertEqual(JumpMath.peakPower(height: 0.6008625, massKg: 90), 5669.235375, accuracy: 1e-6)
    }

    func testOsäkerhetenFörEnBild() {
        XCTAssertEqual(JumpMath.heightUncertainty(flightTime: 0.70, frameInterval: 1.0 / 240), 0.007153125,
                       accuracy: 1e-9)
        XCTAssertEqual(JumpMath.heightUncertainty(flightTime: 0.70, frameInterval: 1.0 / 60), 0.0286125,
                       accuracy: 1e-9)
    }

    func testResultatetSamlarAllt() {
        let r = JumpResult(flightTime: 0.70, frameInterval: 1.0 / 240, massKg: 90)
        XCTAssertEqual(r.height, 0.6008625, accuracy: 1e-9)
        XCTAssertEqual(r.takeoffVelocity, 3.4335, accuracy: 1e-9)
        XCTAssertEqual(r.impulse, 309.015, accuracy: 1e-9)
        XCTAssertEqual(r.peakPower, 5669.235375, accuracy: 1e-6)
        XCTAssertEqual(r.heightUncertainty, 0.007153125, accuracy: 1e-9)
    }
}
