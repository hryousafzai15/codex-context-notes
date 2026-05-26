import SwiftUI

struct NotoMascotView: View {
    var size: CGFloat = 48
    var showShadow = true

    var body: some View {
        ZStack {
            notebook
            bookmark
            rings
            face
            pencil
        }
        .frame(width: size, height: size)
        .shadow(color: showShadow ? .blue.opacity(0.28) : .clear, radius: size * 0.18, y: size * 0.08)
        .accessibilityHidden(true)
    }

    private var notebook: some View {
        RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.46, green: 0.70, blue: 1.0),
                        Color(red: 0.14, green: 0.38, blue: 0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .trailing) {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.06, green: 0.12, blue: 0.22).opacity(0.30))
                    .frame(width: size * 0.18)
                    .padding(.vertical, size * 0.08)
                    .padding(.trailing, size * 0.05)
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: max(1, size * 0.025))
            }
            .frame(width: size * 0.72, height: size * 0.76)
            .rotationEffect(.degrees(-2))
    }

    private var bookmark: some View {
        Path { path in
            let w = size * 0.16
            let h = size * 0.34
            let x = size * 0.58
            let y = size * 0.05
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + w, y: y))
            path.addLine(to: CGPoint(x: x + w, y: y + h))
            path.addLine(to: CGPoint(x: x + w / 2, y: y + h * 0.78))
            path.addLine(to: CGPoint(x: x, y: y + h))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.88, blue: 0.30),
                    Color(red: 0.95, green: 0.60, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay {
            Path { path in
                let w = size * 0.16
                let h = size * 0.34
                let x = size * 0.58
                let y = size * 0.05
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + w, y: y))
                path.addLine(to: CGPoint(x: x + w, y: y + h))
                path.addLine(to: CGPoint(x: x + w / 2, y: y + h * 0.78))
                path.addLine(to: CGPoint(x: x, y: y + h))
                path.closeSubpath()
            }
            .stroke(.white.opacity(0.22), lineWidth: max(0.7, size * 0.012))
        }
    }

    private var rings: some View {
        VStack(spacing: size * 0.09) {
            ForEach(0..<4, id: \.self) { _ in
                Capsule()
                    .fill(Color(red: 0.08, green: 0.11, blue: 0.16))
                    .frame(width: size * 0.20, height: size * 0.045)
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.22), lineWidth: max(0.5, size * 0.008))
                    }
            }
        }
        .offset(x: -size * 0.32, y: size * 0.02)
    }

    private var face: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.03, green: 0.06, blue: 0.10))
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(x: -size * 0.10, y: size * 0.03)

            Circle()
                .fill(Color(red: 0.03, green: 0.06, blue: 0.10))
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(x: size * 0.10, y: size * 0.03)

            Path { path in
                path.move(to: CGPoint(x: size * 0.45, y: size * 0.56))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.55, y: size * 0.56),
                    control: CGPoint(x: size * 0.50, y: size * 0.62)
                )
            }
            .stroke(Color(red: 0.03, green: 0.06, blue: 0.10), style: StrokeStyle(lineWidth: max(1, size * 0.026), lineCap: .round))

            Circle()
                .fill(Color(red: 1.0, green: 0.62, blue: 0.58).opacity(0.70))
                .frame(width: size * 0.065, height: size * 0.035)
                .offset(x: -size * 0.19, y: size * 0.10)

            Circle()
                .fill(Color(red: 1.0, green: 0.62, blue: 0.58).opacity(0.70))
                .frame(width: size * 0.065, height: size * 0.035)
                .offset(x: size * 0.19, y: size * 0.10)
        }
    }

    private var pencil: some View {
        RoundedRectangle(cornerRadius: size * 0.025, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.86, blue: 0.27),
                        Color(red: 0.94, green: 0.45, blue: 0.18)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size * 0.30, height: size * 0.07)
            .overlay(alignment: .trailing) {
                Triangle()
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.15))
                    .frame(width: size * 0.08, height: size * 0.07)
            }
            .rotationEffect(.degrees(-35))
            .offset(x: size * 0.23, y: size * 0.29)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
