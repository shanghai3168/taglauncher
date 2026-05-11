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
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var wiggle = false

    private let hoverScale: CGFloat = 1.22

    var body: some View {
        VStack(spacing: 6) {
            DraggableAppIconView(
                icon: app.icon,
                iconSize: iconSize,
                payload: "\(app.path.path)\n\(sourceTag ?? "")",
                onHover: { isHovered = $0 },
                onLongPress: { onDragModeChange?(true) },
                onDragEnd: { onDragModeChange?(false) },
                onClick: onSelect
            )
            .frame(width: iconSize, height: iconSize)
            .scaleEffect(isHovered ? hoverScale : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.35 : 0),
                radius: isHovered ? 14 : 0,
                y: isHovered ? 8 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: iconSize + 20)
                .opacity(showName ? 1 : (isHovered ? 0.85 : 0))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(RoundedRectangle(cornerRadius: 10))
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

private struct DraggableAppIconView: NSViewRepresentable {
    let icon: NSImage
    let iconSize: CGFloat
    let payload: String
    let onHover: (Bool) -> Void
    let onLongPress: () -> Void
    let onDragEnd: () -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> DragIconNSView {
        let view = DragIconNSView()
        view.image = icon
        view.iconSize = iconSize
        view.payload = payload
        view.onHover = onHover
        view.onLongPress = onLongPress
        view.onDragEnd = onDragEnd
        view.onClick = onClick
        return view
    }

    func updateNSView(_ view: DragIconNSView, context: Context) {
        view.image = icon
        view.iconSize = iconSize
        view.payload = payload
        view.onHover = onHover
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
    var onHover: ((Bool) -> Void)?
    var onLongPress: (() -> Void)?
    var onDragEnd: (() -> Void)?
    var onClick: (() -> Void)?

    private var mouseDownEvent: NSEvent?
    private var didStartDrag = false
    private var isLongPressActive = false
    private var longPressWorkItem: DispatchWorkItem?
    private var trackingAreaRef: NSTrackingArea?

    override var isFlipped: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        trackingAreaRef = area
        addTrackingArea(area)
    }

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

    override func mouseEntered(with event: NSEvent) {
        onHover?(true)
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

    override func mouseExited(with event: NSEvent) {
        if !didStartDrag {
            onHover?(false)
        }
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
