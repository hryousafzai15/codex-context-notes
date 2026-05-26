import AppKit
import SwiftUI

struct NotoMascotView: View {
    var size: CGFloat = 48
    var showShadow = true

    var body: some View {
        Group {
            if let image = Self.notebookImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                fallbackLogo
            }
        }
        .frame(width: size, height: size)
        .shadow(color: showShadow ? .black.opacity(0.24) : .clear, radius: size * 0.18, y: size * 0.08)
        .accessibilityHidden(true)
    }

    private static let notebookImage: NSImage? = {
        if let url = Bundle.main.url(forResource: "NotoTinyNotebook", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "NotoTinyNotebook", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        #endif

        return nil
    }()

    private var fallbackLogo: some View {
        RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.30, green: 0.38, blue: 0.50),
                        Color(red: 0.09, green: 0.13, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
            }
            .frame(width: size, height: size)
    }
}
