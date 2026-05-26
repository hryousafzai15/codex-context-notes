import AppKit
import SwiftUI

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
    }
}

struct GlassPanelBackground: View {
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow)

            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.12, blue: 0.14).opacity(0.88),
                    Color(red: 0.04, green: 0.05, blue: 0.07).opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.28, green: 0.63, blue: 1.0).opacity(0.20),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
            .blendMode(.screen)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                .padding(0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat) -> some View {
        self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func glassCapsule() -> some View {
        self.background(.thinMaterial, in: Capsule())
    }

    func frostedSurface(cornerRadius: CGFloat = 18, opacity: Double = 0.10) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(Color.white.opacity(opacity))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
    }

    func darkField(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .overlay(.thinMaterial.opacity(0.22))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.11), lineWidth: 1)
            }
    }
}
