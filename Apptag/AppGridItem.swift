import SwiftUI
import AppKit

// MARK: - App Grid Item (icon + name card, with Dock-like hover)

struct AppGridItem: View {
    let app: AppInfo
    let iconSize: CGFloat
    var showName: Bool = true
    var sourceTag: String? = nil
    var dragModeActive: Bool = false
    var onDragModeChange: ((Bool) -> Void)? = nil
    var onBubbleHover: ((AppInfo, CGRect, Bool) -> Void)? = nil
    var onEditNote: ((AppInfo, CGRect) -> Void)? = nil
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var wiggle = false
    @State private var globalFrame: CGRect = .zero
    @AppStorage("showUncommonAppBubbles") private var showUncommonAppBubbles = true

    static let hoverScale: CGFloat = 1.22
    static let labelHeight: CGFloat = 14

    static func stableWidth(iconSize: CGFloat) -> CGFloat {
        iconSize * hoverScale + 8
    }

    static func stableHeight(iconSize: CGFloat) -> CGFloat {
        iconSize * hoverScale + labelHeight + 22
    }

    private var iconSlotSize: CGFloat { iconSize * Self.hoverScale }
    private var labelWidth: CGFloat { iconSize + 20 }
    private var labelHeight: CGFloat { Self.labelHeight }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                DraggableAppIconView(
                    icon: app.icon,
                    iconSize: iconSize,
                    payload: "\(app.path.path)\n\(sourceTag ?? "")",
                    onLongPress: { onDragModeChange?(true) },
                    onDragEnd: { onDragModeChange?(false) },
                    onClick: onSelect
                )
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(isHovered ? Self.hoverScale : 1.0)
                .shadow(
                    color: .black.opacity(isHovered ? 0.35 : 0),
                    radius: isHovered ? 14 : 0,
                    y: isHovered ? 8 : 0
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            }
            .frame(width: iconSlotSize, height: iconSlotSize)

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: labelWidth, height: labelHeight)
                .opacity(showName ? 1 : (isHovered ? 0.85 : 0))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(width: Self.stableWidth(iconSize: iconSize), height: Self.stableHeight(iconSize: iconSize))
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { globalFrame = proxy.frame(in: .global) }
                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                        globalFrame = newFrame
                    }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            if showUncommonAppBubbles && app.isUncommon {
                onBubbleHover?(app, globalFrame, hovering)
            }
        }
        .contextMenu {
            if app.isUncommon {
                Button(tr("appNote.edit")) {
                    onEditNote?(app, globalFrame)
                }
            }
        }
        .rotationEffect(.degrees(dragModeActive ? (wiggle ? 2.0 : -2.0) : 0))
        .animation(
            dragModeActive
                ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                : .default,
            value: wiggle
        )
        .onChange(of: dragModeActive) { _, active in
            wiggle = active
        }
    }
}

enum BubblePlacement {
    case above
    case below
}

struct AppNameBubble: View {
    let appName: String
    let note: String?
    let isEditing: Bool
    let placement: BubblePlacement
    @Binding var draftNote: String
    var noteFocused: FocusState<Bool>.Binding
    let onCommit: () -> Void
    let onCancel: () -> Void

    private var displayNote: String {
        note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        content
        .onExitCommand(perform: onCancel)
    }

    private var content: some View {
        VStack(spacing: isEditing || !displayNote.isEmpty ? 8 : 0) {
            Text(appName)
                .font(.system(size: isEditing ? 22 : 24, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity)

            if isEditing {
                VStack(alignment: .trailing, spacing: 4) {
                    TextField(tr("appNote.placeholder"), text: limitedDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.white.opacity(0.12))
                        )
                        .focused(noteFocused)
                        .onSubmit(onCommit)
                    Text("\(draftNote.count) / \(TagDatabase.maxAppNoteLength)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
            } else if !displayNote.isEmpty {
                Text(displayNote)
                    .font(.system(size: 14, weight: .medium))
                    .lineSpacing(2)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, isEditing ? 22 : 24)
        .padding(.vertical, isEditing ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: .black.opacity(0.34), radius: 24, y: 16)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        )
    }

    private var limitedDraft: Binding<String> {
        Binding(
            get: { draftNote },
            set: { draftNote = String($0.prefix(TagDatabase.maxAppNoteLength)) }
        )
    }
}

private struct DraggableAppIconView: NSViewRepresentable {
    let icon: NSImage
    let iconSize: CGFloat
    let payload: String
    let onLongPress: () -> Void
    let onDragEnd: () -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> DragIconNSView {
        let view = DragIconNSView()
        view.image = icon
        view.iconSize = iconSize
        view.payload = payload
        view.onLongPress = onLongPress
        view.onDragEnd = onDragEnd
        view.onClick = onClick
        return view
    }

    func updateNSView(_ view: DragIconNSView, context: Context) {
        view.image = icon
        view.iconSize = iconSize
        view.payload = payload
        view.onLongPress = onLongPress
        view.onDragEnd = onDragEnd
        view.onClick = onClick
        view.needsDisplay = true
    }
}

private final class DragIconNSView: NSView {
    var image: NSImage = NSImage()
    var iconSize: CGFloat = 56
    var payload: String = ""
    var onLongPress: (() -> Void)?
    var onDragEnd: (() -> Void)?
    var onClick: (() -> Void)?

    private var mouseDownEvent: NSEvent?
    private var didStartDrag = false
    private var isLongPressActive = false
    private var longPressWorkItem: DispatchWorkItem?
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = NSRect(
            x: (bounds.width - iconSize) / 2,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        image.draw(in: rect)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didStartDrag = false
        isLongPressActive = false
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.mouseDownEvent != nil else { return }
            self.isLongPressActive = true
            self.onLongPress?()
        }
        longPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    override func mouseDragged(with event: NSEvent) {
        if didStartDrag {
            AppDragCoordinator.shared.updateDragLocation(
                screenPoint(for: event),
                copy: event.modifierFlags.contains(.option)
            )
            return
        }

        guard let mouseDownEvent, isLongPressActive else { return }
        let dx = event.locationInWindow.x - mouseDownEvent.locationInWindow.x
        let dy = event.locationInWindow.y - mouseDownEvent.locationInWindow.y
        guard hypot(dx, dy) > 3 else { return }

        didStartDrag = true
        longPressWorkItem?.cancel()
        AppDragCoordinator.shared.beginDrag(
            image: makeDragImage(),
            payload: payload,
            at: screenPoint(for: event),
            copy: event.modifierFlags.contains(.option),
            in: window
        )
    }

    override func mouseUp(with event: NSEvent) {
        longPressWorkItem?.cancel()
        if didStartDrag {
            AppDragCoordinator.shared.finishDrag(
                at: screenPoint(for: event),
                copy: event.modifierFlags.contains(.option)
            )
            onDragEnd?()
        } else if !isLongPressActive {
            onClick?()
        } else {
            onDragEnd?()
        }
        didStartDrag = false
        isLongPressActive = false
        mouseDownEvent = nil
    }

    private func makeDragImage() -> NSImage {
        let scale: CGFloat = 1.22 * 1.5
        let imageSize = iconSize * scale
        let padding = iconSize * 0.45
        let canvasSize = NSSize(width: imageSize + padding * 2, height: imageSize + padding * 2)
        let dragImage = NSImage(size: canvasSize)

        dragImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
        shadow.shadowBlurRadius = 24
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.set()

        image.draw(in: NSRect(x: padding, y: padding, width: imageSize, height: imageSize))
        dragImage.unlockFocus()
        return dragImage
    }

    private func screenPoint(for event: NSEvent) -> NSPoint {
        window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
    }
}
