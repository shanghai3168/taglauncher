import SwiftUI
import AppKit
import QuartzCore

final class AppDragCoordinator {
    static let shared = AppDragCoordinator()

    struct DropTarget {
        weak var view: AppDropTargetReceivingView?
        var tag: String
    }

    struct EmptyDropTarget {
        weak var view: AppEmptyDropReceivingView?
    }

    private var targets: [UUID: DropTarget] = [:]
    private var emptyTargets: [UUID: EmptyDropTarget] = [:]
    private weak var dragHostWindow: NSWindow?
    private weak var dragLayerHostView: NSView?
    private var dragLayer: CALayer?
    private var normalDragImage: CGImage?
    private var copyDragImage: CGImage?
    private var currentCopyMode = false
    private var dragWindow: NSWindow?
    private var dragImageSize: NSSize = .zero
    private var activePayload = ""
    private weak var hoveredTarget: AppDropTargetReceivingView?

    private init() {}

    var hasActiveDrag: Bool {
        dragLayer != nil || dragWindow != nil || !activePayload.isEmpty
    }

    func register(id: UUID, view: AppDropTargetReceivingView, tag: String) {
        if let existing = targets[id], existing.view === view, existing.tag == tag {
            return
        }
        if targets.count > 256 {
            pruneDeadTargets()
        }
        targets[id] = DropTarget(view: view, tag: tag)
    }

    func unregister(id: UUID) {
        targets.removeValue(forKey: id)
    }

    func registerEmptyDropTarget(id: UUID, view: AppEmptyDropReceivingView) {
        if emptyTargets.count > 64 {
            pruneDeadTargets()
        }
        emptyTargets[id] = EmptyDropTarget(view: view)
    }

    func unregisterEmptyDropTarget(id: UUID) {
        emptyTargets.removeValue(forKey: id)
    }

    func beginDrag(image: NSImage, payload: String, at screenPoint: NSPoint, copy: Bool, in hostWindow: NSWindow?) {
        endDragVisuals()
        activePayload = payload
        dragImageSize = image.size
        dragHostWindow = hostWindow
        currentCopyMode = copy
        normalDragImage = Self.cgImage(from: image)
        copyDragImage = Self.cgImage(from: Self.copyBadgeImage(from: image))

        let hostView: NSView

        if let contentView = hostWindow?.contentView {
            hostView = contentView
        } else {
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
            panel.level = .normal
            panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .stationary, .transient, .ignoresCycle]
            panel.isReleasedWhenClosed = false
            let contentView = NSView(frame: NSRect(origin: .zero, size: image.size))
            panel.contentView = contentView
            dragWindow = panel
            dragHostWindow = panel
            hostView = contentView
            panel.setFrameOrigin(NSPoint(x: screenPoint.x - image.size.width / 2, y: screenPoint.y - image.size.height / 2))
            panel.orderFrontRegardless()
        }

        hostView.wantsLayer = true
        guard let rootLayer = hostView.layer else { return }

        let layer = CALayer()
        layer.bounds = CGRect(origin: .zero, size: image.size)
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.contentsGravity = .resizeAspect
        layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        layer.contents = copy ? copyDragImage : normalDragImage
        layer.zPosition = 1_000_000
        layer.actions = [
            "position": NSNull(),
            "contents": NSNull(),
            "bounds": NSNull(),
            "opacity": NSNull()
        ]

        rootLayer.addSublayer(layer)
        dragLayerHostView = hostView
        dragLayer = layer
        updateDragLocation(screenPoint)
    }

    func updateDragLocation(_ screenPoint: NSPoint, copy: Bool? = nil) {
        if let dragLayer, let dragHostWindow, let hostView = dragLayerHostView {
            if let copy {
                updateCopyMode(copy)
            }
            let windowPoint = dragHostWindow.convertPoint(fromScreen: screenPoint)
            let contentPoint = hostView.convert(windowPoint, from: nil)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            dragLayer.position = contentPoint
            CATransaction.commit()
            updateHoverTarget(at: screenPoint)
            hoveredTarget?.appDragLocationChanged(screenPoint: screenPoint, copy: currentCopyMode)
            return
        }

        guard let dragWindow else {
            updateHoverTarget(at: screenPoint)
            return
        }
        let origin = NSPoint(
            x: screenPoint.x - dragImageSize.width / 2,
            y: screenPoint.y - dragImageSize.height / 2
        )
        dragWindow.setFrameOrigin(origin)
        updateHoverTarget(at: screenPoint)
        hoveredTarget?.appDragLocationChanged(screenPoint: screenPoint, copy: currentCopyMode)
    }

    func finishDrag(at screenPoint: NSPoint, copy: Bool) {
        defer { endDragVisuals() }
        let parts = activePayload.components(separatedBy: "\n")
        guard let path = parts.first, !path.isEmpty else { return }
        let source = parts.dropFirst().first ?? ""
        let sourceContainerID = parts.dropFirst(2).first ?? ""
        pruneDeadTargets()

        if let hitTarget = dropTarget(at: screenPoint) {
            hitTarget.appDragLocationChanged(screenPoint: screenPoint, copy: copy)
            hitTarget.performDrop(
                path: path,
                source: source,
                sourceContainerID: sourceContainerID,
                copy: copy
            )
            return
        }

        let emptyTarget = emptyTargets.values
            .compactMap { target -> (AppEmptyDropReceivingView, CGFloat)? in
                guard let view = target.view,
                      let frame = view.screenFrame(),
                      frame.contains(screenPoint)
                else { return nil }
                return (view, frame.width * frame.height)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0

        emptyTarget?.performEmptyDrop(path: path, source: source, screenPoint: screenPoint, copy: copy)
    }

    func cancelDrag() {
        endDragVisuals()
    }

    private func updateCopyMode(_ copy: Bool) {
        guard currentCopyMode != copy else { return }
        currentCopyMode = copy
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dragLayer?.contents = copy ? copyDragImage : normalDragImage
        CATransaction.commit()
    }

    private func endDragVisuals() {
        hoveredTarget?.appDragHoverChanged(active: false)
        hoveredTarget = nil
        dragLayer?.removeFromSuperlayer()
        dragLayer = nil
        dragLayerHostView = nil
        dragHostWindow = nil
        normalDragImage = nil
        copyDragImage = nil
        currentCopyMode = false
        dragWindow?.orderOut(nil)
        dragWindow = nil
        activePayload = ""
        dragImageSize = .zero
    }

    private func pruneDeadTargets() {
        targets = targets.filter { $0.value.view != nil }
        emptyTargets = emptyTargets.filter { $0.value.view != nil }
    }

    private func updateHoverTarget(at screenPoint: NSPoint) {
        guard hasActiveDrag else { return }
        pruneDeadTargets()
        let nextTarget = dropTarget(at: screenPoint)
        guard nextTarget !== hoveredTarget else { return }
        hoveredTarget?.appDragHoverChanged(active: false)
        nextTarget?.appDragHoverChanged(active: true)
        hoveredTarget = nextTarget
    }

    private func dropTarget(at screenPoint: NSPoint) -> AppDropTargetReceivingView? {
        targets.values
            .compactMap { target -> (AppDropTargetReceivingView, CGFloat)? in
                guard let view = target.view,
                      let frame = view.screenFrame(),
                      frame.contains(screenPoint)
                else { return nil }
                return (view, frame.width * frame.height)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    private static func cgImage(from image: NSImage) -> CGImage? {
        var rect = NSRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: [
            .interpolation: NSImageInterpolation.high
        ])
    }

    private static func copyBadgeImage(from baseImage: NSImage) -> NSImage {
        let image = NSImage(size: baseImage.size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        baseImage.draw(in: NSRect(origin: .zero, size: baseImage.size), from: .zero, operation: .sourceOver, fraction: 1)

        let bounds = NSRect(origin: .zero, size: baseImage.size)
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
        image.unlockFocus()
        return image
    }
}

protocol AppDropTargetReceivingView: AnyObject {
    func screenFrame() -> NSRect?
    func appDragHoverChanged(active: Bool)
    func appDragLocationChanged(screenPoint: NSPoint, copy: Bool)
    func performDrop(path: String, source: String, copy: Bool)
    func performDrop(path: String, source: String, sourceContainerID: String, copy: Bool)
}

protocol AppEmptyDropReceivingView: AnyObject {
    func screenFrame() -> NSRect?
    func performEmptyDrop(path: String, source: String, screenPoint: NSPoint, copy: Bool)
}

extension AppDropTargetReceivingView where Self: NSView {
    func screenFrame() -> NSRect? {
        guard let window else { return nil }
        let rectInWindow = convert(bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }
}

extension AppDropTargetReceivingView {
    func appDragHoverChanged(active: Bool) {}
    func appDragLocationChanged(screenPoint: NSPoint, copy: Bool) {}
    func performDrop(path: String, source: String, sourceContainerID: String, copy: Bool) {
        performDrop(path: path, source: source, copy: copy)
    }
}

extension AppEmptyDropReceivingView where Self: NSView {
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
        view.configure(targetTag: targetTag, onDropApp: onDropApp)
        return view
    }

    func updateNSView(_ view: AppDropTargetNSView, context: Context) {
        view.configure(targetTag: targetTag, onDropApp: onDropApp)
    }

    static func dismantleNSView(_ view: AppDropTargetNSView, coordinator: ()) {
        view.onDropApp = nil
        AppDragCoordinator.shared.unregister(id: view.id)
    }
}

final class AppDropTargetNSView: NSView, AppDropTargetReceivingView {
    let id = UUID()
    var targetTag = ""
    var onDropApp: ((String, String, Bool) -> Void)?

    func configure(targetTag: String, onDropApp: @escaping (String, String, Bool) -> Void) {
        let tagChanged = self.targetTag != targetTag
        self.targetTag = targetTag
        self.onDropApp = onDropApp
        if tagChanged {
            registerTarget()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            AppDragCoordinator.shared.unregister(id: id)
        } else {
            registerTarget()
        }
    }

    func registerTarget() {
        guard window != nil else { return }
        AppDragCoordinator.shared.register(id: id, view: self, tag: targetTag)
    }

    func performDrop(path: String, source: String, copy: Bool) {
        onDropApp?(path, source, copy)
    }

    deinit {
        AppDragCoordinator.shared.unregister(id: id)
    }
}
