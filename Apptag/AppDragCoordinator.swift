import SwiftUI
import AppKit

final class AppDragCoordinator {
    static let shared = AppDragCoordinator()

    struct DropTarget {
        weak var view: NSView?
        var tag: String
        var onDrop: (String, String, Bool) -> Void
    }

    private var targets: [UUID: DropTarget] = [:]
    private weak var dragHostWindow: NSWindow?
    private weak var dragPreviewSuperview: NSView?
    private var dragPreviewView: DragPreviewView?
    private var dragWindow: NSWindow?
    private var dragImageSize: NSSize = .zero
    private var activePayload = ""

    private init() {}

    func register(id: UUID, view: NSView, tag: String, onDrop: @escaping (String, String, Bool) -> Void) {
        targets[id] = DropTarget(view: view, tag: tag, onDrop: onDrop)
    }

    func unregister(id: UUID) {
        targets.removeValue(forKey: id)
    }

    func beginDrag(image: NSImage, payload: String, at screenPoint: NSPoint, copy: Bool, in hostWindow: NSWindow?) {
        endDragVisuals()
        activePayload = payload
        dragImageSize = image.size
        dragHostWindow = hostWindow

        if let contentView = hostWindow?.contentView {
            let preview = DragPreviewView(image: image, copy: copy, frame: NSRect(origin: .zero, size: image.size))
            preview.translatesAutoresizingMaskIntoConstraints = true
            preview.autoresizingMask = []
            contentView.addSubview(preview, positioned: .above, relativeTo: nil)
            preview.layer?.zPosition = 1_000_000
            dragPreviewSuperview = contentView
            dragPreviewView = preview
            updateDragLocation(screenPoint)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: image.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .stationary, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false

        panel.contentView = DragPreviewView(image: image, copy: copy, frame: NSRect(origin: .zero, size: image.size))

        dragWindow = panel
        updateDragLocation(screenPoint)
        panel.setFrame(panel.frame, display: true)
        panel.orderFrontRegardless()
    }

    func updateDragLocation(_ screenPoint: NSPoint, copy: Bool? = nil) {
        if let dragPreviewView, let dragHostWindow, let contentView = dragPreviewSuperview {
            if let copy {
                dragPreviewView.isCopyMode = copy
            }
            let windowPoint = dragHostWindow.convertPoint(fromScreen: screenPoint)
            let contentPoint = contentView.convert(windowPoint, from: nil)
            dragPreviewView.setFrameOrigin(
                NSPoint(
                    x: contentPoint.x - dragImageSize.width / 2,
                    y: contentPoint.y - dragImageSize.height / 2
                )
            )
            return
        }

        guard let dragWindow else { return }
        let origin = NSPoint(
            x: screenPoint.x - dragImageSize.width / 2,
            y: screenPoint.y - dragImageSize.height / 2
        )
        dragWindow.setFrameOrigin(origin)
    }

    func finishDrag(at screenPoint: NSPoint, copy: Bool) {
        defer { endDragVisuals() }
        let parts = activePayload.components(separatedBy: "\n")
        guard let path = parts.first, !path.isEmpty else { return }
        let source = parts.dropFirst().first ?? ""

        let hitTarget = targets.values
            .compactMap { target -> (DropTarget, CGFloat)? in
                guard let frame = target.view?.screenFrame(), frame.contains(screenPoint) else { return nil }
                return (target, frame.width * frame.height)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0

        hitTarget?.onDrop(path, source, copy)
    }

    func cancelDrag() {
        endDragVisuals()
    }

    private func endDragVisuals() {
        dragPreviewView?.removeFromSuperview()
        dragPreviewView = nil
        dragPreviewSuperview = nil
        dragHostWindow = nil
        dragWindow?.orderOut(nil)
        dragWindow = nil
        activePayload = ""
        dragImageSize = .zero
    }
}

private final class DragPreviewView: NSView {
    private let image: NSImage
    var isCopyMode: Bool {
        didSet {
            if oldValue != isCopyMode {
                needsDisplay = true
            }
        }
    }

    init(image: NSImage, copy: Bool, frame: NSRect) {
        self.image = image
        self.isCopyMode = copy
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0)

        guard isCopyMode else { return }

        let badgeSize = min(bounds.width, bounds.height) * 0.28
        let badgeRect = NSRect(
            x: bounds.maxX - badgeSize - badgeSize * 0.22,
            y: bounds.maxY - badgeSize - badgeSize * 0.22,
            width: badgeSize,
            height: badgeSize
        )

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.set()
        NSColor.systemGreen.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()
        NSGraphicsContext.restoreGraphicsState()

        let plus = "+"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: badgeSize * 0.78, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let plusSize = plus.size(withAttributes: attrs)
        plus.draw(
            at: NSPoint(
                x: badgeRect.midX - plusSize.width / 2,
                y: badgeRect.midY - plusSize.height / 2 + badgeSize * 0.03
            ),
            withAttributes: attrs
        )
    }
}

private extension NSView {
    func screenFrame() -> NSRect? {
        guard let window else { return nil }
        let rectInWindow = convert(bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }
}

struct AppDropTargetView: NSViewRepresentable {
    let targetTag: String
    let onDropApp: (String, String, Bool) -> Void

    func makeNSView(context: Context) -> AppDropTargetNSView {
        let view = AppDropTargetNSView()
        view.targetTag = targetTag
        view.onDropApp = onDropApp
        return view
    }

    func updateNSView(_ view: AppDropTargetNSView, context: Context) {
        view.targetTag = targetTag
        view.onDropApp = onDropApp
        view.registerTarget()
    }

    static func dismantleNSView(_ view: AppDropTargetNSView, coordinator: ()) {
        AppDragCoordinator.shared.unregister(id: view.id)
    }
}

final class AppDropTargetNSView: NSView {
    let id = UUID()
    var targetTag = ""
    var onDropApp: ((String, String, Bool) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        registerTarget()
    }

    override func layout() {
        super.layout()
        registerTarget()
    }

    func registerTarget() {
        guard window != nil, let onDropApp else { return }
        AppDragCoordinator.shared.register(id: id, view: self, tag: targetTag, onDrop: onDropApp)
    }
}
