import Foundation

/// Var i videon hoppet är markerat. METOD M5
///
/// Båda markeringarna är den FÖRSTA bilden i ett nytt läge: första bilden där
/// fötterna är i luften, och första bilden där de är på marken igen. Då ligger
/// det verkliga avstampet och den verkliga landningen båda inom bilden före
/// markeringen, och felen tar ut varandra i snitt.
public struct FlightMarking: Codable, Equatable, Sendable {
    public var firstAirFrame: Int
    public var landingFrame: Int

    public init(firstAirFrame: Int, landingFrame: Int) {
        self.firstAirFrame = firstAirFrame
        self.landingFrame = landingFrame
    }
}

public enum MarkingError: Error, Equatable, Sendable {
    case outOfRange
    case landingNotAfterTakeoff
    /// Tiden i luften är kortare än `FrameClock.shortest`.
    case tooShort
    /// Tiden i luften är längre än `FrameClock.longest`. Det vanligaste skälet
    /// är en slow motion-video som sparats om till 30 bilder/s med nedsaktningen
    /// inbakad, så att tiden blir 8 gånger för lång. METOD M5
    case tooLong
}

/// Videons bildtider i sekunder, i visningsordning. Tiderna läses ur filen och
/// räknas inte fram ur en nominell bildfrekvens, eftersom iPhone-video kan ha
/// ojämn takt. METOD M5
public struct FrameClock: Equatable, Sendable {
    /// 0,15 s motsvarar knappt 3 cm.
    public static let shortest = 0.15
    /// 1,0 s motsvarar 1,23 m, högre än något stående hopp.
    public static let longest = 1.0

    public let times: [Double]

    public init(times: [Double]) {
        self.times = times.sorted()
    }

    /// En jämn klocka, för tester och för filer som saknar egna tider.
    public init(frameRate: Double, count: Int) {
        self.times = (0..<count).map { Double($0) / frameRate }
    }

    public var count: Int { times.count }

    /// Medianavståndet mellan bilderna, i sekunder.
    public var frameInterval: Double {
        guard times.count > 1 else { return 0 }
        let steps = zip(times.dropFirst(), times).map { $0 - $1 }.sorted()
        return steps[steps.count / 2]
    }

    /// Bilder per sekund ur medianavståndet, avrundat till heltal.
    public var frameRate: Double {
        frameInterval > 0 ? (1 / frameInterval).rounded() : 0
    }

    public func flightTime(_ m: FlightMarking) throws -> Double {
        guard times.indices.contains(m.firstAirFrame), times.indices.contains(m.landingFrame) else {
            throw MarkingError.outOfRange
        }
        guard m.landingFrame > m.firstAirFrame else { throw MarkingError.landingNotAfterTakeoff }
        let t = times[m.landingFrame] - times[m.firstAirFrame]
        if t < Self.shortest { throw MarkingError.tooShort }
        if t > Self.longest { throw MarkingError.tooLong }
        return t
    }
}
