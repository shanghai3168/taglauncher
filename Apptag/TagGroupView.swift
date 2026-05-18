import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tag Group Section (with centered separator-line header)

struct TagGroupView: View {
    let group: TagGroup
    let onSelectApp: (AppInfo) -> Void
    let tagFontSize: CGFloat
    let iconSize: CGFloat
    var showNames: Bool = true
    var dragModeActive: Bool = false
    var onDragModeChange: ((Bool) -> Void)? = nil
    var onBubbleHover: ((AppInfo, CGRect, Bool) -> Void)? = nil
    var onEditNote: ((AppInfo, CGRect) -> Void)? = nil
    var bubbleDisabled: Bool = false
    @Binding var hoveredAppItemID: String?
    var onDropApp: ((String, String, Bool) -> Void)? = nil

    /// Adaptive columns — auto-fit based on icon size and available width.
    private var columns: [GridItem] {
        let itemWidth = AppGridItem.stableWidth(iconSize: iconSize)
        return [GridItem(.adaptive(minimum: itemWidth, maximum: itemWidth + 36), spacing: 6)]
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
                        sourceTag: group.name,
                        dragModeActive: dragModeActive,
                        onDragModeChange: onDragModeChange,
                        onBubbleHover: onBubbleHover,
                        onEditNote: onEditNote,
                        bubbleDisabled: bubbleDisabled,
                        itemID: "\(group.name)|\(app.path.path)",
                        hoveredAppItemID: $hoveredAppItemID,
                        onSelect: { onSelectApp(app) }
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .overlay {
            AppDropTargetView(targetTag: group.name) { path, source, copy in
                onDropApp?(path, source, copy)
            }
            .allowsHitTesting(false)
        }
        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            let text: String?
            if let data = item as? Data {
                text = String(data: data, encoding: .utf8)
            } else if let string = item as? String {
                text = string
            } else if let string = item as? NSString {
                text = string as String
            } else {
                text = nil
            }
            guard let text else { return }
            let parts = text.components(separatedBy: "\n")
            guard let path = parts.first, !path.isEmpty else { return }
            let source = parts.dropFirst().first ?? ""
            let copy = NSEvent.modifierFlags.contains(.option)
            DispatchQueue.main.async {
                onDropApp?(path, source, copy)
            }
        }
        return true
    }
}
