import SwiftUI

// MARK: - Tag Group Section (with centered separator-line header)

struct TagGroupView: View {
    let group: TagGroup
    let onSelectApp: (AppInfo) -> Void
    let tagFontSize: CGFloat
    let iconSize: CGFloat
    var showNames: Bool = true

    /// Adaptive columns — auto-fit based on icon size and available width.
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: iconSize + 28, maximum: iconSize + 64), spacing: 6)]
    }

    // Subtle separator line color — adapts to light/dark mode
    private var lineColor: Color {
        .secondary.opacity(0.25)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Centered separator line with tag name
            HStack(spacing: 0) {
                Rectangle()
                    .fill(lineColor)
                    .frame(height: 1)

                Text(group.name)
                    .font(.system(size: tagFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)

                Rectangle()
                    .fill(lineColor)
                    .frame(height: 1)
            }
            .padding(.bottom, 6)

            // App icon grid — columns auto-adjust to icon size
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(group.apps) { app in
                    AppGridItem(
                        app: app,
                        iconSize: iconSize,
                        showName: showNames,
                        onSelect: { onSelectApp(app) }
                    )
                }
            }
        }
    }
}
