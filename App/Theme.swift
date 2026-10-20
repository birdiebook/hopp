import SwiftUI
import Jump

/// Formspråket (BESLUT B13): mörk botten, en accentfärg (volt), stora smala siffror.
enum Theme {
    static let ground = Color(hex: 0x0B0D10)
    static let surface = Color(hex: 0x15181D)
    static let raised = Color(hex: 0x1F242B)
    static let line = Color(hex: 0x262B33)
    static let text = Color(hex: 0xF2F4F7)
    static let secondary = Color(hex: 0x9BA3AF)
    static let accent = Color(hex: 0xC8FF2E)
    /// Text och ikoner på accentfärgen.
    static let onAccent = Color(hex: 0x0B0D10)
    static let warning = Color(hex: 0xFFB020)
    static let record = Color(hex: 0xFF453A)

    /// Siffrorna: SF Pro i smal bredd, så att stora tal ryms.
    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }

    static let caption = Font.system(size: 13, weight: .medium)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension View {
    /// Ett kort på mörk botten.
    func card(padding: CGFloat = 18, radius: CGFloat = 24) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: radius))
    }

    /// Liten versal rubrik över ett kort.
    func overline() -> some View {
        self.font(Theme.caption)
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(Theme.secondary)
    }
}

/// Den stora knappen i accentfärgen.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.8 : 1), in: .capsule)
    }
}

/// Den mörka knappen bredvid.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.surface.opacity(configuration.isPressed ? 0.7 : 1), in: .capsule)
    }
}

enum Format {
    static func cm(_ meters: Double) -> String {
        (meters * 100).formatted(.number.precision(.fractionLength(1)))
    }

    static func whole(_ x: Double) -> String {
        x.formatted(.number.precision(.fractionLength(0)))
    }

    static func ms(_ seconds: Double) -> String {
        (seconds * 1000).formatted(.number.precision(.fractionLength(0)))
    }

    static func percent(_ change: Double) -> String {
        (change * 100).formatted(.number.precision(.fractionLength(0)).sign(strategy: .always()))
    }

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}

extension JumpStyle {
    var name: String {
        switch self {
        case .handsOnHips: return "CMJ"
        case .armSwing: return "CMJ med armsving"
        }
    }
}
