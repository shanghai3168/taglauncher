import SwiftUI
import AppKit

// MARK: - App Grid Item (icon + name card, with Dock-like hover)

struct AppGridItem: View {
    let app: AppInfo
    let iconSize: CGFloat
    var showName: Bool = true
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .scaleEffect(isHovered ? 1.22 : 1.0)
                    .shadow(
                        color: .black.opacity(isHovered ? 0.35 : 0),
                        radius: isHovered ? 14 : 0,
                        y: isHovered ? 8 : 0
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)

                if showName {
                    Text(app.name)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: iconSize + 20)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
