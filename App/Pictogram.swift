import SwiftUI

/// Hopparen som piktogram (BESLUT B13): tjocka rundade lemmar, fristående huvud
/// och det bortre benet mörkare. Ritas i en ruta på 60 × 200 punkter med fötterna
/// vid y = 200, och skalas till den höjd vyn får.
struct Pictogram: View {
    var near = Color(hex: 0xD5D9DF)
    var far = Color(hex: 0x6B737E)
    var arm = Color(hex: 0xA9B0BA)

    var body: some View {
        Canvas { ctx, size in
            let s = size.height / 200
            ctx.translateBy(x: (size.width - 60 * s) / 2, y: 0)
            ctx.scaleBy(x: s, y: s)
            func limb(_ points: [CGPoint], _ width: CGFloat, _ color: Color) {
                var p = Path()
                p.addLines(points)
                ctx.stroke(p, with: .color(color),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            limb([.init(x: 32, y: 104), .init(x: 38, y: 148), .init(x: 36, y: 186)], 15, far)
            limb([.init(x: 36, y: 192), .init(x: 48, y: 192)], 9, far)
            limb([.init(x: 28, y: 40), .init(x: 28, y: 100)], 24, near)
            limb([.init(x: 27, y: 104), .init(x: 22, y: 148), .init(x: 24, y: 186)], 16, near)
            limb([.init(x: 24, y: 192), .init(x: 37, y: 192)], 9, near)
            limb([.init(x: 29, y: 48), .init(x: 15, y: 72), .init(x: 29, y: 88)], 11, arm)
            ctx.fill(Path(ellipseIn: CGRect(x: 14, y: 0, width: 30, height: 30)), with: .color(near))
        }
        .aspectRatio(60.0 / 200.0, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Uppställningen som bild: telefonen på golvet i sidled, 2–3 m bort, i fotledshöjd.
struct SetupIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let floor = h * 0.84
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: .init(x: 0, y: floor))
                    p.addLine(to: .init(x: w, y: floor))
                }
                .stroke(Theme.line, lineWidth: 2)

                Path { p in
                    p.move(to: .init(x: w * 0.2, y: floor - 16))
                    p.addLine(to: .init(x: w * 0.68, y: floor - 16))
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.accent)
                    .frame(width: 16, height: 28)
                    .offset(x: w * 0.13, y: floor - 28)

                Pictogram()
                    .frame(height: floor - 20)
                    .offset(x: w * 0.68, y: 20)

                Path { p in
                    let y = floor + 18
                    p.move(to: .init(x: w * 0.18, y: y))
                    p.addLine(to: .init(x: w * 0.74, y: y))
                    p.move(to: .init(x: w * 0.18, y: y - 6))
                    p.addLine(to: .init(x: w * 0.18, y: y + 6))
                    p.move(to: .init(x: w * 0.74, y: y - 6))
                    p.addLine(to: .init(x: w * 0.74, y: y + 6))
                }
                .stroke(Theme.secondary, lineWidth: 1.5)

                Text("2–3 m")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: w, alignment: .center)
                    .offset(y: floor + 22)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Telefonen står på golvet i sidled, 2 till 3 meter bort, med kameran i fotledshöjd")
    }
}
