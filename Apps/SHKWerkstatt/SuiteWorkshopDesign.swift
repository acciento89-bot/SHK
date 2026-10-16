import SwiftUI

/// Original scalable illustrations, decorative rather than engineering diagrams.
struct SuiteEquipmentIcon: View {
    let module: SuiteModule
    var body: some View {
        Canvas { context, size in
            var c = context
            c.scaleBy(x: size.width / 100, y: size.height / 100)
            func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat = 4) {
                var p = Path(); p.addLines(points)
                c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            func box(_ rect: CGRect, _ color: Color, radius: CGFloat = 5) {
                let p = Path(roundedRect: rect, cornerRadius: radius)
                c.fill(p, with: .linearGradient(Gradient(colors: [color, color.opacity(0.58)]), startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
                c.stroke(p, with: .color(color.opacity(0.85)), lineWidth: 1)
            }
            func ring(_ rect: CGRect, _ color: Color, _ width: CGFloat = 3) {
                c.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: width)
            }
            let metal = SuiteTheme.silver
            switch module {
            case .heat:
                line([CGPoint(x: 19, y: 27), CGPoint(x: 19, y: 79), CGPoint(x: 83, y: 79)], SuiteTheme.copper, 6)
                for x in stride(from: 29, through: 69, by: 10) { box(CGRect(x: CGFloat(x), y: 20, width: 7, height: 54), metal, radius: 3) }
                line([CGPoint(x: 30, y: 18), CGPoint(x: 76, y: 18)], metal, 4)
                line([CGPoint(x: 19, y: 28), CGPoint(x: 27, y: 28)], SuiteTheme.copper, 5)
                line([CGPoint(x: 78, y: 40), CGPoint(x: 86, y: 40)], SuiteTheme.copper, 5)
                box(CGRect(x: 82, y: 34, width: 8, height: 12), module.tint, radius: 2)
            case .pipe:
                let p = [CGPoint(x: 14, y: 69), CGPoint(x: 36, y: 69), CGPoint(x: 36, y: 33), CGPoint(x: 78, y: 33), CGPoint(x: 78, y: 77)]
                line(p, SuiteTheme.copper.opacity(0.6), 13); line(p, SuiteTheme.copper, 8)
                for r in [CGRect(x: 19, y: 61, width: 7, height: 16), CGRect(x: 28, y: 47, width: 16, height: 7), CGRect(x: 70, y: 56, width: 16, height: 7)] { box(r, metal, radius: 2) }
                line([CGPoint(x: 54, y: 20), CGPoint(x: 54, y: 31)], metal, 3)
                line([CGPoint(x: 44, y: 18), CGPoint(x: 65, y: 18)], module.tint, 5)
            case .volume:
                box(CGRect(x: 28, y: 17, width: 45, height: 64), metal, radius: 12)
                box(CGRect(x: 33, y: 42, width: 35, height: 33), module.tint.opacity(0.9), radius: 7)
                line([CGPoint(x: 33, y: 84), CGPoint(x: 33, y: 88)], metal, 4)
                line([CGPoint(x: 68, y: 84), CGPoint(x: 68, y: 88)], metal, 4)
                line([CGPoint(x: 20, y: 29), CGPoint(x: 27, y: 29)], SuiteTheme.copper, 6)
                line([CGPoint(x: 74, y: 68), CGPoint(x: 82, y: 68)], SuiteTheme.copper, 6)
                for y in stride(from: 29, through: 65, by: 9) { line([CGPoint(x: 57, y: CGFloat(y)), CGPoint(x: 63, y: CGFloat(y))], SuiteTheme.ink, 2) }
            case .air:
                box(CGRect(x: 17, y: 17, width: 66, height: 66), metal.opacity(0.35), radius: 10)
                ring(CGRect(x: 23, y: 23, width: 54, height: 54), metal, 3)
                for angle in [0.0, 2.0944, 4.1888] {
                    var blade = Path()
                    blade.move(to: CGPoint(x: 50, y: 50))
                    blade.addCurve(to: CGPoint(x: 50, y: 28), control1: CGPoint(x: 40, y: 38), control2: CGPoint(x: 36, y: 24))
                    blade.addCurve(to: CGPoint(x: 55, y: 48), control1: CGPoint(x: 68, y: 28), control2: CGPoint(x: 67, y: 47))
                    blade.closeSubpath()
                    let t = CGAffineTransform(translationX: -50, y: -50).concatenating(CGAffineTransform(rotationAngle: angle)).concatenating(CGAffineTransform(translationX: 50, y: 50))
                    c.fill(blade.applying(t), with: .color(module.tint))
                }
                c.fill(Path(ellipseIn: CGRect(x: 44, y: 44, width: 12, height: 12)), with: .color(metal))
            case .cold:
                box(CGRect(x: 22, y: 49, width: 57, height: 12), SuiteTheme.copper, radius: 3)
                for (x, color) in [(CGFloat(31), Color(red: 0.42, green: 0.73, blue: 1)), (CGFloat(67), SuiteTheme.copper)] {
                    c.fill(Path(ellipseIn: CGRect(x: x-13, y: 18, width: 26, height: 26)), with: .color(SuiteTheme.paper))
                    ring(CGRect(x: x-13, y: 18, width: 26, height: 26), color)
                    line([CGPoint(x: x, y: 43), CGPoint(x: x, y: 49)], metal, 3)
                    line([CGPoint(x: x, y: 32), CGPoint(x: x+5, y: 26)], metal, 2)
                    line([CGPoint(x: x, y: 62), CGPoint(x: x, y: 81), CGPoint(x: x+9, y: 87)], color, 4)
                }
                ring(CGRect(x: 17, y: 51, width: 10, height: 10), module.tint)
                ring(CGRect(x: 74, y: 51, width: 10, height: 10), module.tint)
            case .service:
                box(CGRect(x: 25, y: 18, width: 51, height: 67), metal.opacity(0.75), radius: 6)
                box(CGRect(x: 29, y: 24, width: 43, height: 56), SuiteTheme.paper, radius: 3)
                box(CGRect(x: 40, y: 14, width: 22, height: 12), SuiteTheme.copper, radius: 4)
                for y in [CGFloat(39), 55, 71] {
                    line([CGPoint(x: 35, y: y), CGPoint(x: 39, y: y+4), CGPoint(x: 45, y: y-4)], module.tint, 2.5)
                    line([CGPoint(x: 52, y: y), CGPoint(x: 64, y: y)], metal, 2.5)
                }
            }
        }.aspectRatio(1, contentMode: .fit)
    }
}

struct SuiteWorkshopHero: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 9) {
                Label(S("FÜR DEIN HANDWERK", "BUILT FOR YOUR TRADE"), systemImage: "wrench.and.screwdriver")
                    .font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(SuiteTheme.copper)
                Text(S("Dein Einsatz.\nAlles im Griff.", "Your next job.\nAll in hand."))
                    .font(.system(.title, design: .rounded).weight(.bold)).fixedSize(horizontal: false, vertical: true)
                Text(S("Wärme, Wasser, Luft und Kälte.\nEine Werkstatt für deine Anlagen.", "Heating, water, air and cooling.\nOne workshop for your systems."))
                    .font(.subheadline).foregroundStyle(SuiteTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }.padding(20)
            Image("WorkshopHero").resizable().scaledToFit().accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [SuiteTheme.raised, SuiteTheme.paper], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SuiteTheme.line))
    }
}

struct SuiteSectionHeading: View {
    let title: String
    var detail: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.caption.weight(.bold)).tracking(1.3).foregroundStyle(SuiteTheme.secondary)
            Spacer(minLength: 8)
            if let detail { Text(detail).font(.caption.monospacedDigit()).foregroundStyle(SuiteTheme.copper) }
        }.accessibilityElement(children: .combine)
    }
}

struct SuitePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(SuiteTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 26).padding(.vertical, 14).padding(.horizontal, 16)
            .background(LinearGradient(colors: [Color(red: 1, green: 0.77, blue: 0.54), SuiteTheme.copper], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.22)))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
            .shadow(color: SuiteTheme.copper.opacity(enabled ? 0.12 : 0), radius: 12, y: 5)
    }
}

extension View {
    func suiteFormSurface() -> some View {
        scrollContentBackground(.hidden).background(SuiteTheme.canvas)
            .toolbarBackground(SuiteTheme.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
