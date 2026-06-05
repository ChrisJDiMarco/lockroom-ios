import SwiftUI

enum LockroomPalette {
    static let black = Color(red: 0.035, green: 0.043, blue: 0.037)
    static let chamber = Color(red: 0.075, green: 0.085, blue: 0.074)
    static let emulsion = Color(red: 0.945, green: 0.918, blue: 0.850)
    static let paper = Color(red: 0.988, green: 0.974, blue: 0.930)
    static let nickel = Color(red: 0.560, green: 0.610, blue: 0.570)
    static let fog = Color(red: 0.720, green: 0.750, blue: 0.700)
    static let cinnabar = Color(red: 0.850, green: 0.130, blue: 0.085)
    static let cyan = Color(red: 0.240, green: 0.780, blue: 0.740)
    static let gold = Color(red: 0.980, green: 0.680, blue: 0.260)
}

struct LockroomBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LockroomPalette.black,
                    LockroomPalette.chamber,
                    Color(red: 0.13, green: 0.11, blue: 0.085)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            FilmGrain()
                .blendMode(.softLight)
                .opacity(0.30)
        }
        .ignoresSafeArea()
    }
}

struct FilmGrain: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<150 {
                let x = CGFloat((index * 47) % 100) / 100 * size.width
                let y = CGFloat((index * 71) % 100) / 100 * size.height
                let opacity = Double((index % 9) + 2) / 100
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }
}

struct SectionLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(LockroomPalette.cyan)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(LockroomPalette.fog)
            Spacer()
        }
        .tracking(1.2)
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LockroomPalette.paper.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(LockroomPalette.paper.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

struct SmallStatusPill: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.14))
                .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
        )
    }
}

