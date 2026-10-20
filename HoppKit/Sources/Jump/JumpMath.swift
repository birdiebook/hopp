import Foundation

/// Hoppets fysik. Allt i SI-enheter: sekunder, meter, kilogram.
public enum JumpMath {
    /// Tyngdacceleration. METOD M1
    public static let g = 9.81

    /// Höjden ur tiden i luften: h = g·t²/8. METOD M1
    public static func height(flightTime t: Double) -> Double {
        g * t * t / 8
    }

    /// Tiden i luften för en höjd (inversen av `height`). METOD M1
    public static func flightTime(height h: Double) -> Double {
        (8 * h / g).squareRoot()
    }

    /// Farten när fötterna lämnar marken: v = g·t/2. METOD M2
    public static func takeoffVelocity(flightTime t: Double) -> Double {
        g * t / 2
    }

    /// Nettoimpulsen i avstampet: massa × avstampsfart, i N·s. METOD M3
    public static func impulse(flightTime t: Double, massKg: Double) -> Double {
        massKg * takeoffVelocity(flightTime: t)
    }

    /// Uppskattad toppeffekt i watt (Sayers 1999), höjden i meter. METOD M4
    public static func peakPower(height h: Double, massKg: Double) -> Double {
        60.7 * (h * 100) + 45.3 * massKg - 2055
    }

    /// Hur mycket höjden ändras om tiden i luften är fel med `dt`. Används som
    /// osäkerheten för en bild: dh ≈ g·t·dt/4. METOD M5
    public static func heightUncertainty(flightTime t: Double, frameInterval dt: Double) -> Double {
        g * t * dt / 4
    }
}

/// Ett hopps resultat, uträknat ur tiden i luften.
public struct JumpResult: Equatable, Sendable {
    public let flightTime: Double
    public let height: Double
    public let takeoffVelocity: Double
    public let impulse: Double
    public let peakPower: Double
    /// ± i meter för en bild åt något håll. METOD M5
    public let heightUncertainty: Double

    public init(flightTime: Double, frameInterval: Double, massKg: Double) {
        self.flightTime = flightTime
        height = JumpMath.height(flightTime: flightTime)
        takeoffVelocity = JumpMath.takeoffVelocity(flightTime: flightTime)
        impulse = JumpMath.impulse(flightTime: flightTime, massKg: massKg)
        peakPower = JumpMath.peakPower(height: height, massKg: massKg)
        heightUncertainty = JumpMath.heightUncertainty(flightTime: flightTime, frameInterval: frameInterval)
    }
}
